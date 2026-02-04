import boto3

REGION = "us-east-1"

ec2 = boto3.client('ec2', region_name=REGION)

def check_subnets():
    subnets = ec2.describe_subnets()['Subnets']
    for subnet in subnets:
        if subnet['MapPublicIpOnLaunch'] and subnet['CidrBlock'].startswith("10.0.1"):
            print(f"[COMPLIANCE ALERT] Private subnet {subnet['SubnetId']} has public IP mapping!")

def check_security_groups():
    sgs = ec2.describe_security_groups()['SecurityGroups']
    for sg in sgs:
        for perm in sg.get('IpPermissions', []):
            for ip_range in perm.get('IpRanges', []):
                if ip_range.get('CidrIp') == '0.0.0.0/0' and perm.get('FromPort') in [22, 3389]:
                    print(f"[COMPLIANCE ALERT] SG {sg['GroupName']} allows unrestricted SSH/RDP!")

if __name__ == "__main__":
    print("Running compliance checks...")
    check_subnets()
    check_security_groups()
    print("Compliance check complete.")
