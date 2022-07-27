
/* This script is used to change a user's TeamDynamix security role, client portal security role, and ticketing
   application security role. It also sets the available applications for the user depending on their roles.
   
   All credentials and identifiable information are NOT included. THIS WILL NOT RUN. */


# TeamDynamix web API base link
$uri = "https:///*institutionName*/.teamdynamix.com/TDWebApi/api/"

# API content requirement
$thisContent = "application/json; charset=utf-8"


# This function authenticates to the TDX API and returns the authorization token for future API calls
function authorization {

    $authUri = $uri + "auth/loginadmin"
    $authBody = '{BEID: "/*institutionBEID*/", WebServicesKey: "/*institutionWebServicesKey*/"}'
    $authKey = Invoke-RestMethod -Uri $authUri -ContentType $thisContent -Method Post -Body $authBody

    # Create $authHeader dictionary and assign $authKey response token
    $authHeader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $authHeader.Add("Authorization", ("Bearer " + $authKey))

    # Return the TDX authorization token
    return $authHeader
}


# This function displays the role menu for the user to choose the new role. It requires the
# authorization token and the name of the user whose role is being changed.
function chooseNewRole ($auth, $name) {

    $role = ""

    DO {
        # The role menu is displayed, and the number entered will be assigned to the $choice variable
        $choice = Read-Host "`n Choose TeamDynamix role for $name `n`n [1] Administrator --------------- A Teamdynamix administrator.
 [2] Manager ---------------------- IT Directors, Assistant Directors, and Supervisors.`n [3] Project Management Office --- Members of the PMO.
 [4] Executive ------------------- Leadership who need elevated client access.`n [5] Technician ------------------- Full time IT personnel not in a supervisory role.
 [6] Student Technician ----------- Part time IT personnel (Help Desk).`n [7] Client ----------------------- Minimal access for clients and former IT personnel.`n [8] Exit`n`n"
    
        switch ($choice) {
            1 {$role = "administrator"}
            2 {$role = "manager"}
            3 {$role = "pmo"}
            4 {$role = "executive"}
            5 {$role = "technician"}
            6 {$role = "student"}
            7 {$role = "client"}
            8 {exit}
            Default {"`n`nIncorrect choice`n`n"}
        }
    } Until (($choice -gt 1) -and ($choice -lt 9))

    # Return the new role
    return $role
}


# This function finds the unique identifier of the user whose role is being changed. It requires
# the authorization token and the ID of the user.
function findUid ($auth, $idNumber) {

   $argTestResult = ""

   # Test user input
   DO {
       # ID argument can't be null
       if ($idNumber -eq $null){
           $idNumber = Read-Host "`n`nPlease enter a valid ID.`n`n"
       }
       # UNFID must be nine characters
       elseif ($idNumber.Length -ne 9){
           $idNumber = Read-Host "`n`nInvalid ID. Please enter a valid ID.`n`n"
       }
       else {
           $searchUri = $uri + "people/lookup?searchText=" + $idNumber + "&maxResults=1"
           $info = Invoke-RestMethod -Method Get -Uri $searchUri -ContentType $thisContent -Headers $auth

           # TDX user search returned zero results, meaning the ID is invalid
           if ($info.Length -eq 0){
               $idNumber = Read-Host "`n`nInvalid ID. Please enter a valid ID.`n`n"
           }
           else {
               $userId = $info | Select-Object -ExpandProperty UID
               $userName = $info | Select-Object -ExpandProperty FullName
               $userUid = @($userId, $userName)

               # Set the flag to exit the DO Until loop
               $argTestResult = "good"
           }
       }
   } Until ($argTestResult -eq "good")

   # Return the array containing the user UID and full name
   return $userUid
}


# This function assigns the user a new role. It requires the authentication token, the 
# user UID, and the user's new role value.
function changeRole ($auth, $usrUid, $usrRole) {

    [guid[]]$uidArray = @($usrUid)

    switch ($usrRole) {
        "client" {           
            $globalRole = "/*globalRoleGuid*/"
            $clientPortalRole = "/*clientPortalRoleGuid*/"
            $clientRoleName = "Client"
            $apps = @("")
        }
        "student" {
            $globalRole = "/*globalRoleGuid*/"
            $clientPortalRole = "/*clientPortalRoleGuid*/"
            $clientRoleName = "Student Technician"
            $marComClientPortalRole = "/*marCommClientPortalRoleGuid*/"
            $marComClientRoleName = "Client"
            $ticketRole = "/*ticketRoleGuid*/"
            $ticketRoleName = "Technician"
            $apps = @("TDFileCabinet","MyWork","TDPeople","TDProjects","TDNext","TDTimeExpense")
        }
        "technician" {
            $globalRole = "/*globalRoleGuid*/"
            $clientPortalRole = "/*clientPortalRoleGuid*/"
            $clientRoleName = "Technician"
            $marComClientPortalRole = "/*marCommClientPortalRoleGuid*/"
            $marComClientRoleName = "Client"
            $ticketRole = "/*ticketRoleGuid*/"
            $ticketRoleName = "Technician"
            $apps = @("TDFileCabinet","MyWork","TDPeople","TDProjects","TDNext","TDTimeExpense")
        }
        "pmo" {
            $globalRole = "/*globalRoleGuid*/"
            $clientPortalRole = "/*clientPortalRoleGuid*/"
            $clientRoleName = "Manager"
            $marComClientPortalRole = "/*marCommClientPortalRoleGuid*/"
            $marComClientRoleName = "Client"
            $ticketRole = "/*ticketRoleGuid*/"
            $ticketRoleName = "Manager"
            $apps = @("TDAnalysis","TDFileCabinet","TDFinance","MyWork","TDPeople","TDPP","TDPortfolios","TDTemplate","TDProjects","TDResourceManagement","TDNext","TDTimeExpense")
        }
        "executive" {
            $globalRole = "/*globalRoleGuid*/"
            $clientPortalRole = "/*clientPortalRoleGuid*/"
            $clientRoleName = "Client Project Requestor"
            $marComClientPortalRole = "/*marCommClientPortalRoleGuid*/"
            $marComClientRoleName = "Client"
            $apps = @("TDAnalysis","TDFileCabinet","TDFinance","MyWork","TDPP","TDPortfolios","TDProjects","TDResourceManagement","TDNext")
        }
        "manager" {
            $globalRole = "/*globalRoleGuid*/"
            $clientPortalRole = "/*clientPortalRoleGuid*/"
            $clientRoleName = "Manager"
            $marComClientPortalRole = "/*marCommClientPortalRoleGuid*/"
            $marComClientRoleName = "Client"
            $ticketRole = "/*ticketRoleGuid*/"
            $ticketRoleName = "Manager"
            $apps = @("TDAnalysis","TDFileCabinet","TDFinance","MyWork","TDPeople","TDPP","TDPortfolios","TDProjects","TDResourceManagement","TDNext","TDTimeExpense")
        }
        "administrator" {
            $globalRole = "/*globalRoleGuid*/"
            $clientPortalRole = "/*clientPortalRoleGuid*/"
            $clientRoleName = "Administrator"
            $marComClientPortalRole = "/*marCommClientPortalRoleGuid*/"
            $marComClientRoleName = "Client"
            $ticketRole = "/*ticketRoleGuid*/"
            $ticketRoleName = "Administrator"
            $apps = @("TDAnalysis","TDCommunity","TDFileCabinet","TDFinance","MyWork","TDPeople","TDPP","TDPortfolios","TDTemplate","TDProjects","TDResourceManagement","TDNext","TDTimeExpense")
        }
    }

    # Create the URI to change the global security role (also good for bulk users)
    $globalRoleUri = $uri + "people/bulk/changesecurityrole/" + $globalRole

    # Create the URI to change the application security role(s) (also good for bulk users)
    $appRoleUri = $uri + "people/bulk/changeorgapplications"

    # Create the URI to assign the user a set of applications (also good for bulk users)
    $appsUri = $uri + "people/bulk/changeapplications"

    $appRoles = @(
        @{
            # Variables for the  Client Portal
            SecurityRoleID=$clientPortalRole
            SecurityRoleName=$clientRoleName
            IsAdministrator="False"
            ID="/*clientPortalId*/"
        },
        @{
            # Variables for the Ticketing application
            SecurityRoleID=$ticketRole
            SecurityRoleName=$ticketRoleName
            IsAdministrator="False"
            ID="/*ticketingAppId*/"
        }
    )

    # This is the body of the api call to change the application security role.
    $body = @(
        @{
            UserUids=$uidArray
            OrgApplications=$appRoles
            ReplaceExistingOrgApplications="True"
        }
    )

    # This is the body of the api call that assigns the user different applications.
    $appbody = @(
        @{
            ApplicationNames=$apps
            UserUids=$uidArray
            ReplaceExistingApplications="True"
        }
    )

    $a = ConvertTo-Json $uidArray
    $b = $body | ConvertTo-Json
    $c = $appbody | ConvertTo-Json

    # Change the global security role
    Invoke-RestMethod -Method Post -Uri $globalRoleUri -Headers $auth -ContentType $thisContent -Body $a

    # Change the application security roles (client portal & ticketing app)
    Invoke-RestMethod -Method Post -Uri $appRoleUri -Headers $auth -ContentType $thisContent -Body $b

    # Change the available applications
    Invoke-RestMethod -Method Post -Uri $appsUri -Headers $auth -ContentType $thisContent -Body $c
}


# Call the authorization function to authenticate into TDX and assign token to a variable
$token = authorization

# Call the findUid function to get the user's unique identifier and full name and assign to a variable
$techUid = findUid -auth $token -idNumber $args[0]

# Display menu for user to decide the new role and assign keyboard input to a variable
$newRole = chooseNewRole -auth $token -name $techUid[1]

# Change the user's TeamDynamix roles
changeRole -auth $token -usrUid $techUid[0] -usrRole $newRole
