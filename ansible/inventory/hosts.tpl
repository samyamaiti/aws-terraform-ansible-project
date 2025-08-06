[ec2_instances]
%{ for instance in instances ~}
${instance.public_ip} ansible_host=${instance.public_ip} instance_id=${instance.id} private_ip=${instance.private_ip}
%{ endfor ~}
