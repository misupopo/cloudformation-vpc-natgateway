export interface CommonParams {
  ProjectName: string;
}

export interface TargetParams {
  VpcCidrParam: string;
  PrivateAZASubnetBlock: string;
  PublicAZASubnetBlock: string;
  PrivateAZBSubnetBlock: string;
  PublicAZBSubnetBlock: string;
  PrivateAZCSubnetBlock: string;
  PublicAZCSubnetBlock: string;
  HighlyAvailableNat: string;
  EnableVpcFlowLogs: string;
}
