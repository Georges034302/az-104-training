# Lab: Create CPU Alert and Action Group (Portal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create an Action Group and CPU metric alert for a VM, then validate alert rule scope and action routing.

## What you will build

 [VM CPU Metric]
      |
      v
 [Metric Alert Rule]
      |
      v
 [Action Group]
      |
      v
 [Email Notification]

## Estimated time
40-55 minutes

## Cost + safety
- One VM is used as alert signal target.
- Alert emails may be sent when threshold conditions are met.
- Delete resources after validation.

## Prerequisites
- Azure subscription with rights to create VM and Monitor resources
- Azure Portal access
- A valid email inbox for Action Group testing

## Setup (Portal values to use)
Use the following values when entering names and settings in the portal steps:

- LOCATION: australiaeast
- PREFIX: az104
- LAB: m05alerts
- RG_NAME: ${PREFIX}-${LAB}-rg
- VM_NAME: ${PREFIX}-${LAB}-vm
- AG_NAME: ${PREFIX}-${LAB}-ag
- ALERT_NAME: ${PREFIX}-${LAB}-cpu-high

## Portal solution (step-by-step)
### 1) Create the resource group and VM
1. Open Resource groups and create ${RG_NAME} in ${LOCATION}.
2. Open Virtual machines and create ${VM_NAME} in ${RG_NAME}.
3. Choose Ubuntu Server 22.04 LTS and a small size (B1s or equivalent).
4. Complete deployment.

### 2) Create Action Group
1. Open Monitor.
2. Select Alerts > Action groups > Create.
3. In Basics:
  - Resource group: ${RG_NAME}
  - Action group name: ${AG_NAME}
  - Display name: m05ag
4. In Notifications:
  - Notification type: Email/SMS/Push/Voice
  - Name: OpsEmail
  - Email: your monitored inbox
5. Select Review + create, then Create.

### 3) Create CPU metric alert rule
1. Open ${VM_NAME}.
2. Select Alerts > Create > Alert rule.
3. Scope should already be the VM. Confirm scope is correct.
4. Condition:
  - Signal type: Metric
  - Signal name: Percentage CPU
  - Aggregation: Average
  - Operator: Greater than
  - Threshold: 70
  - Evaluation granularity: 1 minute
  - Lookback period: 5 minutes
5. Actions:
  - Select existing Action Group ${AG_NAME}.
6. Details:
  - Alert rule name: ${ALERT_NAME}
  - Severity: 2
  - Enable rule on creation: Yes
7. Select Review + create, then Create.

### 4) Validate
1. Open Monitor > Alerts > Alert rules.
2. Confirm ${ALERT_NAME} is Enabled and scoped to ${VM_NAME}.
3. Open the alert rule and verify ${AG_NAME} is attached under Actions.
4. Optional: generate CPU load on VM and check Monitor > Alerts > Fired alerts.

## Cleanup (required)
- In Azure Portal, open **Resource groups** and select `${RG_NAME}`.
- Select **Overview** > **Delete resource group**.
- Enter `${RG_NAME}` to confirm deletion, then select **Delete**.
- Wait for deployment notifications to confirm cleanup is complete.
- Delete the local `.env` file from your lab folder.

## Notes
- Start with meaningful thresholds based on baseline workload behavior.
- Action Groups are reusable and should be standardized by environment.
