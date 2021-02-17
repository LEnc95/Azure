Get-msoluser #| Where-Object {$_.strongauthenticationmethods -ne $null} | select -First 100

<#
 $RequiredGroupID= "14DayEnrollmentGroupID"
 $TargetGroupID= "MFAEnforcementGroupID"
    
    
 $users= Get-MsolGroupMember -GroupObjectId $RequiredGroupID |  Select ObjectID
    
 foreach($user in $users){Get-MsolUser -objectid $user.objectid | select DisplayName,UserPrincipalName,ObjectID,@{N="MFAStatus"; E={ 
 if( $_.StrongAuthenticationMethods -ne $NULL) 
 {
    
 Add-MsolGroupMember -GroupObjectId $TargetGroupID -GroupMemberType User -GroupMemberObjectId $_.ObjectId
 } 
 else
  {
  "Not Enrolled"
  }
  }
  }
  }
#>