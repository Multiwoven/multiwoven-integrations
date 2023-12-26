# Salesforce Connector Configuration and Credential Retrieval Guide

## Prerequisite Requirements

Before initiating the Salesforce connector setup, ensure you have an appropriate Salesforce edition. This setup requires either the Enterprise edition of Salesforce, the Professional Edition with an API access add-on, or the Developer edition. For further information on API access within Salesforce, please consult the [Salesforce documentation](https://developer.salesforce.com/docs/).

## Developer Edition Account Creation

If you need a Developer edition of Salesforce, you can register at [Salesforce Developer Signup](https://developer.salesforce.com/signup).

## Step 1: Setting Up a Read-Only User for Multiwoven (Optional, Recommended)

It is advisable to establish a dedicated read-only Salesforce user for Multiwoven to bolster security and manage data access. Follow these instructions to set up this user:

1. Access your Salesforce account using administrator credentials.
2. Go to **Setup** by clicking the gear icon in the top right corner.
3. In the left-hand sidebar, under **Administration**, select **Users > Profiles**.
4. Initiate a new profile by selecting **New profile** in the Profiles area.
5. Choose **Read only** for the **Existing Profile** and name it `Multiwoven Read Only User`.
6. Save this new profile and then go back to edit it.
7. In the permissions section, ensure the **Read** option is checked for the necessary objects in both **Standard Object Permissions** and **Custom Object Permissions**.
8. Save your permission changes.
9. Proceed to **Users > Users** under **Administration**.
10. In the All Users section, add a new user by clicking **New User** and completing the required fields:
    - Select **Salesforce** for the **License**.
    - Set the **Profile** to `Multiwoven Read Only User`.
    - Enter an email address that you can access in the **Email** field.
11. Save the new user details and record the **Username**. Verify the new Salesforce account with the specified email and set up a password during this process.

## Step 2: Obtaining Specific OAuth Credentials for Multiwoven Open Source

For Multiwoven Open Source, certain OAuth credentials are necessary for authentication. These credentials include:

- Access Token
- Refresh Token
- Instance URL
- Client ID
- Client Secret

Acquire these specific OAuth credentials by adhering to the process outlined in this [walkthrough](https://medium.com/@bpmmendis94/obtain-access-refresh-tokens-from-salesforce-rest-api-a324fe4ccd9b), while keeping in mind these adjustments:

- When generating OAuth tokens, use the credentials of the read-only user you previously set up.
