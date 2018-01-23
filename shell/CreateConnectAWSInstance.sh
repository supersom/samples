#!/bin/bash

# you have to configure `aws configure` with your credentials before running this script

#cd ~

image_id=ami-82f4dae7 #ami-597d553c

default_sec_group_name=default

#instance_type=t2.micro 
#instance_type=t2.xlarge
instance_type=t2.2xlarge 
#instance_type=g3.4xlarge

root_volume_snapshot_id_default=snap-0c7dd06b7b368dc22 #snap-0017875283767a2e5
snapshot_filepath=~/.aws-snapshot

bgr_backup_log=~/.aws-bgr-backup-log
cat "" > $bgr_backup_log 2&>1

volume_resize_to_500_flag=1 # might have to start with the default 8GB root volume and resize it to desired size - here, 500GB is used
force_keep_attached_root=1 # when an instance is created, it always has a default EBS root volume attached. This flag forces that root volume to remain, instead of attaching an existing snapshot generated one

force_new_instance=0 # might have to create a new instance inspite of having an instance with the same config, in order to handle additional workload
if [ ! $force_new_instance -eq 1 ]; then
    force_keep_attached_root=0 
fi
force_default_snapshot=0 # might have to deliberately ignore the snapshot backed up onto file, although by default, the one on file has higher priority

keypair_filepath=~/Downloads/administrator-key-pair-useast2.pem
key_name=`basename $keypair_filepath`
key_name=${key_name%.pem}
echo "key_name: $key_name"

#=========================================
# No configuration code after this line
#=========================================

root_volume_snapshot_id=`cat $snapshot_filepath`
echo "Root volume snapshot: $root_volume_snapshot_id read from file"
if [ -z $root_volume_snapshot_id -o $force_default_snapshot -eq 1 ]; then
    root_volume_snapshot_id=$root_volume_snapshot_id_default
    echo "Default root volume snapshot: $root_volume_snapshot_id will be used"
fi

# find if there is a group with an ingress rule to SSH into port 22. If not, authorize such ingress to default_group_name
sec_group_name_with_rule=
sec_group_name_with_rule=`aws ec2 describe-security-groups --filters Name=ip-permission.from-port,Values=22 Name=ip-permission.to-port,Values=22 Name=ip-permission.cidr,Values='0.0.0.0/0' --query 'SecurityGroups[*].{Name:GroupName}' --output text`
echo "Name of the security group with SSH rule: $sec_group_name_with_rule"
if [ -z $sec_group_name_with_rule ]; then
    echo `aws ec2 authorize-security-group-ingress --group-name $default_sec_group_name --protocol tcp --port 22 --cidr 0.0.0.0/0`
    sec_group_name_with_rule=$default_sec_group_name
    echo "Sec group name with SSH rule set up: $sec_group_name_with_rule"
fi

# find the group id of the security group with the SSH ingress rule. If unavailable, authorize such ingress to default_group_name and find its group id
sec_group_id_with_rule=
sec_group_id_with_rule=`aws ec2 describe-security-groups --group-name $sec_group_name_with_rule --query 'SecurityGroups[*].{Name:GroupId}' --output text`
echo "Group ID of the security group with SSH rule: $sec_group_id_with_rule"
if [ -z $sec_group_id_with_rule ]; then
    echo `aws ec2 authorize-security-group-ingress --group-name $default_sec_group_name --protocol tcp --port 22 --cidr 0.0.0.0/0`
    sec_group_id_with_rule=`aws ec2 describe-security-groups --group-name $default_sec_group_name --query 'SecurityGroups[*].{Name:GroupId}' --output text`
    echo "Sec group ID with SSH rule set up: $sec_group_id_with_rule"
fi

# Find if there is an instance [running or stopped] with the given image_id and instance_type, in the given sec group.
# If there are none,
#   Create a new instance.
# Else,
#   If there are multiple,
#       Choose the oldest one as instance_id_with_my_specs.
#   If there is 1,
#       Choose that as instance_id_with_my_specs.
#   Check if instance_id_with_my_specs is running, else start it.
desired_state_name=[running,stopped]
instance_id_with_my_specs=(`aws ec2 describe-instances --filters "Name=instance-state-name, Values=$desired_state_name" "Name=instance-type,Values=$instance_type" "Name=image-id,Values=$image_id" "Name=instance.group-id,Values=$sec_group_id_with_rule" --query 'Reservations[*].Instances[*].{Name:InstanceId}' --output text`)
if [ -z "$instance_id_with_my_specs" -o "$force_new_instance" -eq 1 ]; then
    echo "No instances found - have to create new"
    # Also try this option - --block-device-mappings DeviceName=/dev/sda,Ebs={SnapshotId=snap-05f0acc825cb9ee58} 
    instance_id_with_my_specs=`aws ec2 run-instances --image-id $image_id --security-group-ids $sec_group_id --count 1 --instance-type $instance_type --key-name $key_name --query 'Instances[0].InstanceId' --output text`
    echo "new instance_id: $instance_id_with_my_specs"
    
    if [ -z "$instance_id_with_my_specs" ]; then
        echo "Instance with your requested specs could not be created. Please investigate."
        exit
    else
        state_name=
        desired_state_name=running
        while [ "$state_name" != "$desired_state_name" ]; do
            state_name=`aws ec2 describe-instances --instance-ids $instance_id_with_my_specs --query 'Reservations[*].Instances[*].State.Name' --output text`
            echo "Starting instance: $instance_id_with_my_specs - current state: $state_name"
        done
    fi
else
    if [ ${#instance_id_with_my_specs} -gt 1 ]; then
        echo "Multiple instances with the required config found: ${instance_id_with_my_specs[@]}"
        echo "Connecting to the oldest: ${instance_id_with_my_specs[0]}"
        instance_id_with_my_specs=${instance_id_with_my_specs[0]}
    elif [ ${#instance_id_with_my_specs} -eq 1 ]; then
        state_name=`aws ec2 describe-instances --filters "Name=instance-id, Values=$instance_id_with_my_specs" -query 'Reservations[*].Instances[*].State.Name' --output text`
        echo "There is a $state_name instance with $image_id in $sec_group_id_with_rule ($sec_group_name_with_rule) on a $instance_type, and its instance_id is: $instance_id_with_my_specs"    
    fi
fi

if [ ! -z "$root_volume_snapshot_id" -a  $force_keep_attached_root -eq 0 ]; then
    # Stopping instance_id_with_my_specs to be able to unmount, create (from snapshot) and mount a new root volume
    instance_state=`aws ec2 describe-instances --instance-ids $instance_id_with_my_specs --query 'Reservations[*].Instances[*].State.Name' --output text`
    echo "Stopping instance: $instance_id_with_my_specs - current state: $instance_state"
    desired_state_name=stopped
    if [ $instance_state != $desired_state_name ]; then
        instance_state=`aws ec2 stop-instances --instance-ids $instance_id_with_my_specs --query 'StoppingInstances[*].CurrentState.Name' --output text`
        echo "Stopping instance: $instance_id_with_my_specs - current state: $instance_state"
    fi
    while [ $instance_state != $desired_state_name ]; do
        instance_state=`aws ec2 describe-instances --instance-ids $instance_id_with_my_specs --query 'Reservations[*].Instances[*].State.Name' --output text`    
        echo "Stopping instance: $instance_id_with_my_specs - current state: $instance_state"
    done
    
    # Finding the availability zone of instance_id_with_my_specs
    availability_zone=`aws ec2 describe-instances --instance-ids $instance_id_with_my_specs --query 'Reservations[*].Instances[*].Placement.AvailabilityZone' --output text`
    echo "Selected instance: $instance_id_with_my_specs is in availability zone: $availability_zone"
    
    # Detaching the present root volume to plug in a new root volume created from snapshot
    # Finding the volume-id of the root volume - assuming root device name is /dev/sda1
    root_volume_id=`aws ec2 describe-instances --instance-ids $instance_id_with_my_specs --filters 'Name=block-device-mapping.device-name,Values=/dev/sda1' --query 'Reservations[*].Instances[*].BlockDeviceMappings[*].Ebs.VolumeId' --output text`
    if [ ! -z $root_volume_id ]; then
        echo "Root volume of instance: $instance_id_with_my_specs is $root_volume_id"
        
        # Check the state of the volume with root_volume_id
        volume_state=`aws ec2 describe-volumes --volume-id $root_volume_id --query 'Volumes[*].State' --output text`
        echo "The current root volume: $root_volume_id is $volume_state"
        
        # Detaching the current root volume - monitoring until 'available'
        desired_volume_state=available
        if [ $volume_state != $desired_volume_state ]; then
            volume_state=`aws ec2 detach-volume --volume-id $root_volume_id --force --query 'State' --output text`
            echo "The current root volume: $root_volume_id is $volume_state"
        fi
        while [ $volume_state != $desired_volume_state ]; do
            volume_state=`aws ec2 describe-volumes --volume-id $root_volume_id --query 'Volumes[*].State' --output text`
            echo "The current root volume: $root_volume_id is $volume_state"
        done
        
        # Delete the detached root volume
        aws ec2 delete-volume --volume-id $root_volume_id
        sleep 10
        volume_check=`aws ec2 describe-volumes --volume-id $root_volume_id --query 'Volumes[*].VolumeId' --output text`
        if [ -z "$volume_check" ]; then
            echo "The current root volume: $root_volume_id is deleted"
        else
            echo "The current root volume: $root_volume_id is not deleted: $volume_check"
        fi
    else
        echo "No root volume attached to the instance. Creating one from snapshot and attaching"
    fi
    
    # Creating a volume from snapshot root_volume_snapshot_id in the same availability zone as instance_id_with_my_specs
    if [ $volume_resize_to_500_flag -eq 1 ]; then
        id_root_volume_from_snapshot=`aws ec2 create-volume --availability-zone $availability_zone --snapshot-id $root_volume_snapshot_id --size 500 --query 'VolumeId' --output text`
    else
        id_root_volume_from_snapshot=`aws ec2 create-volume --availability-zone $availability_zone --snapshot-id $root_volume_snapshot_id --query 'VolumeId' --output text`
    fi
    
    # Check the state of the new volume with id_root_volume_from_snapshot
    volume_state=dummy
    desired_volume_state=available
    while [ $volume_state != $desired_volume_state ]; do
        volume_state=`aws ec2 describe-volumes --volume-id $id_root_volume_from_snapshot --query 'Volumes[*].State' --output text`
        echo "The new root volume: $id_root_volume_from_snapshot created from snapshot: $root_volume_snapshot_id is $volume_state"
    done
    
    # Attaching the volume to instance_id_with_my_specs as root volume (device: /dev/sda1) - monitoring until it is 'in-use'
    desired_volume_state=in-use
    if [ $volume_state != $desired_volume_state ]; then
        volume_state=`aws ec2 attach-volume --volume-id $id_root_volume_from_snapshot --instance-id $instance_id_with_my_specs --device /dev/sda1 --query 'State' --output text`
        echo "The new root volume: $id_root_volume_from_snapshot created from snapshot: $root_volume_snapshot_id is $volume_state"
    fi
    while [ $volume_state != $desired_volume_state ]; do
        volume_state=`aws ec2 describe-volumes --volume-id $id_root_volume_from_snapshot --query 'Volumes[*].State' --output text`
        echo "The new root volume: $id_root_volume_from_snapshot created from snapshot: $root_volume_snapshot_id is $volume_state"
    done
else
    instance_has_root_volume=`aws ec2 describe-instances --instance-ids $instance_id_with_my_specs --filter 'Name=block-device-mapping.device-name,Values=/dev/sda1' --query 'Reservations[*].Instances[*].BlockDeviceMappings[*].Ebs.VolumeId' --output text`
    if [ -z "$instance_has_root_volume" ]; then
        echo
        echo "Selected instance: $instance_id_with_my_specs has neither a root volume attached nor a snapshot to create it from"
        echo "You have to create a volume (without snapshot) and attach it to this instance"
        echo "Else, terminate this instance and I will create a new one for you (with a default root volume)"
        echo
        echo "Exiting..."
        exit
    fi    
fi

find_root_volume () {
    # Finding the volume-id of the root volume - assuming root device name is /dev/sda1
    root_volume_id=`aws ec2 describe-instances --instance-ids $instance_id_with_my_specs --filters 'Name=block-device-mapping.device-name,Values=/dev/sda1' --query 'Reservations[*].Instances[*].BlockDeviceMappings[*].Ebs.VolumeId' --output text`
    echo "Root volume of instance: $instance_id_with_my_specs is $root_volume_id"
    
    # Check the state of the volume with root_volume_id
    volume_state=`aws ec2 describe-volumes --volume-id $root_volume_id --query 'Volumes[*].State' --output text`
    echo "The current root volume: $root_volume_id is $volume_state"    
}

detach_root_volume () {    
    # Detaching the current root volume - monitoring until 'available'
    desired_volume_state=available
    if [ $volume_state != $desired_volume_state ]; then
        volume_state=`aws ec2 detach-volume --volume-id $root_volume_id --force --query 'State' --output text`
        echo "The current root volume: $root_volume_id is $volume_state"
    fi
    while [ $volume_state != $desired_volume_state ]; do
        volume_state=`aws ec2 describe-volumes --volume-id $root_volume_id --query 'Volumes[*].State' --output text`
        echo "The current root volume: $root_volume_id is $volume_state"
    done    
}

backup_root_volume () {
    # Check if another snapshot is being created from the same volume
    current_state=dummy
    desired_state=completed
    while [ ! -z "$current_state" -a "$current_state" != "$desired_state" ]; do
        current_state=(`aws ec2 describe-snapshots --filters Name=volume-id,Values=$root_volume_id --query 'Snapshots[*].State' --output text`)
        current_state=${current_state[*]:0:1}
        pending_snapshot_id=(`aws ec2 describe-snapshots --filters Name=volume-id,Values=$root_volume_id --query 'Snapshots[*].SnapshotId' --output text`)
        pending_snapshot_id=${pending_snapshot_id[*]:0:1}
        echo "State of a latest snapshot: $pending_snapshot_id from volume: $root_volume_id: $current_state. Wait until it completes."
    done

    # Create a snapshot of the root volume - monitor until 'completed'
    new_snapshot_id=`aws ec2 create-snapshot --volume-id $root_volume_id --query 'SnapshotId' --output text`
    echo "Making new snapshot: $new_snapshot_id from volume: $root_volume_id"
    
    current_state=dummy
    desired_state=completed
    while [ $current_state != $desired_state ]; do
        current_state=`aws ec2 describe-snapshots --snapshot-id $new_snapshot_id --query 'Snapshots[*].State' --output text`
        echo "The new snapshot: $new_snapshot_id from volume: $root_volume_id is $current_state"
    done
    
    root_volume_snapshot_id=`cat $snapshot_filepath`
    
    # write it to a file
    echo $new_snapshot_id > $snapshot_filepath
    
    if [ "$root_volume_snapshot_id" != "$root_volume_snapshot_id_default" ]; then
        aws ec2 delete-snapshot --snapshot-id $root_volume_snapshot_id
        sleep 10
        snapshot_check=`aws ec2 describe-snapshots --snapshot-id $root_volume_snapshot_id --query 'Snapshots[*].SnapshotId' --output text`
        if [ -z "$snapshot_check" ]; then
            echo "The current snapshot: $root_volume_snapshot_id is deleted"
        else
            echo "The current snapshot: $root_volume_snapshot_id is not deleted: $snapshot_check"
        fi
    else
        echo "The current snapshot: $root_volume_snapshot_id is the default - shouldn't delete that"
    fi
    root_volume_snapshot_id=$new_snapshot_id    
}

delete_root_volume () {
    # Delete the detached root volume
    aws ec2 delete-volume --volume-id $root_volume_id
    sleep 10
    volume_check=`aws ec2 describe-volumes --volume-id $root_volume_id --query 'Volumes[*].VolumeId' --output text`
    if [ -z "$volume_check" ]; then
        echo "The current root volume: $root_volume_id is deleted"
    else
        echo "The current root volume: $root_volume_id is not deleted: $volume_check"
    fi    
}

# Once an instance has been created/started and a volume has been attached to it,
# exit_sequence does a routine shoutdown of the instance after backing up the root volume
# to a snapshot and deleting it.
exit_sequence () {
    # Stopping the running instance_id_with_my_specs once SSH is disconnected
    instance_stopping_state=running
    desired_instance_state=stopped
    while [ $instance_stopping_state != $desired_instance_state ]; do
        instance_stopping_state=`aws ec2 stop-instances --instance-ids $instance_id_with_my_specs --query 'StoppingInstances[*].CurrentState.Name' --output text`
        echo "The instance: $instance_id_with_my_specs is $instance_stopping_state"
    done
    
    find_root_volume
    
    detach_root_volume
    
    sleep 15 # another backup (snapshotting) might be in progress
    
    backup_root_volume
    
    delete_root_volume
    
    exit
}

# Starting a stopped instance_id_with_my_specs - retrying until 'running'
instance_state=`aws ec2 describe-instances --instance-ids $instance_id_with_my_specs --query 'Reservations[*].Instances[*].State.Name' --output text`
desired_state_name=running
if [ -z "$instance_state" ]; then
    echo "The instance: $instance_id_with_my_specs must return a state. Exiting. Please retry."
    exit_sequence
fi

if [ $instance_state != $desired_state_name ]; then
    instance_state=`aws ec2 start-instances --instance-ids $instance_id_with_my_specs --query 'StartingInstances[*].CurrentState.Name' --output text`
    echo "Restarting stopped instance: $instance_id_with_my_specs with the new root volume: $id_root_volume_from_snapshot created from snapshot: $root_volume_snapshot_id - current state: $instance_state"
fi
while [ $instance_state != $desired_state_name ]; do
    instance_state=`aws ec2 describe-instances --instance-ids $instance_id_with_my_specs --query 'Reservations[*].Instances[*].State.Name' --output text`    
    echo "Restarting stopped instance: $instance_id_with_my_specs with the new root volume: $id_root_volume_from_snapshot created from snapshot: $root_volume_snapshot_id - current state: $instance_state"    
done

# Fire background repeated backup of the root volume
while true; do
    echo "Repeated intermittent backup of root volume: Starting (in background)" >> $bgr_backup_log 
    find_root_volume >> $bgr_backup_log 2&>1
    if [ ! -z "$root_volume_id" ]; then
        echo "Repeated intermittent backup of root volume: $root_volume_id - volume is in $volume_state state" >> $bgr_backup_log 
        backup_root_volume >> $bgr_backup_log 2&>1
    else
        echo "Repeated intermittent backup of root volume: No root volume to back up. Process exiting..." >> $bgr_backup_log 
        exit
    fi
    echo "Repeated intermittent backup of root volume: Done and waiting (in background)" >> $bgr_backup_log 
    sleep 60
done &

# Find the public IP of the running instance_id_with_my_specs
instance_pub_ip=`aws ec2 describe-instances --instance-ids $instance_id_with_my_specs --query 'Reservations[*].Instances[*].PublicIpAddress' --output text`
echo "instance_pub_ip: $instance_pub_ip"

##This is a script to generate and add keys for an unseen IP to known_hosts - doesn't work quite as expected - keeping under wraps for the moment
#if [ -z `ssh-keygen -F $instance_pub_ip` ]; then
#  ssh-keyscan -H $instance_pub_ip >> ~/.ssh/known_hosts
#fi
#sleep 10

# Connect to instance_id_with_my_specs over SSH, using keypair
sleep 5
keypress_timeout=5000
while true; do
    #ssh -X -o "StrictHostKeyChecking no" -i $keypair_filepath ubuntu@$instance_pub_ip
    ssh -o "StrictHostKeyChecking no" -L 5901:localhost:5901 -i $keypair_filepath ubuntu@$instance_pub_ip
    echo "Hit 'y' (within $keypress_timeout secs) if you want to reconnect to the SSH; otherwise let's close the session"
    read -t $keypress_timeout -N 1 input >> /dev/null
    echo && echo "Your choice is: $input"
    if [ "$input" != y  -o  -z "$input" ]; then
        echo "Closing the session..."
        break
    fi
done
exit_sequence
