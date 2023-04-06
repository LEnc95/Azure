# Learn how to set this up.
Get-Help New-DCStaleAccountReport -Full


# Export stale Azure AD account report to Excel.
$Parameters = @{
    ClientID = ''
    ClientSecret = ''
    LastSeenDaysAgo = 30
}

New-DCStaleAccountReport @Parameters


# Export stale GUEST Azure AD account report to Excel.
$Parameters = @{
    ClientID = ''
    ClientSecret = ''
    LastSeenDaysAgo = 60
    OnlyGuests = $true
}

New-DCStaleAccountReport @Parameters


# Export stale MEMBER Azure AD account report to Excel.
$Parameters = @{
    ClientID = ''
    ClientSecret = ''
    LastSeenDaysAgo = 60
    OnlyMembers = $true
}

New-DCStaleAccountReport @Parameters


# Export stale GUEST Azure AD account report with group/team membership to Excel.
$Parameters = @{
    ClientID = ''
    ClientSecret = ''
    LastSeenDaysAgo = 60
    OnlyGuests = $true
    IncludeMemberOf = $true
}

New-DCStaleAccountReport @Parameters
