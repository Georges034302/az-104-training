# Lab: Service Health and Resource Health Alerts (Portal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create subscription-scoped Activity Log alerts for Service Health and Resource Health and send notifications through one shared Action Group.

## What you will build

 [Service Health Events] ------+
                              |
 [Resource Health Events] ----+--> [Activity Log Alert Rules] --> [Action Group] --> [Email Receiver]

## Estimated time
30-45 minutes

## Cost + safety
- This lab creates monitor configuration only (very low direct cost).
- Alerts are subscription scoped; validate scope carefully before saving.

## Prerequisites
- Azure subscription with rights to create Monitor resources
- Azure Portal access
- Valid email inbox for alert notifications

## Setup: create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m05healthalerts"
RG_NAME="${PREFIX}-${LAB}-rg"
AG_NAME="${PREFIX}-${LAB}-ag"
SERVICE_ALERT_NAME="${PREFIX}-${LAB}-service"
RESOURCE_ALERT_NAME="${PREFIX}-${LAB}-resource"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, AG_NAME=$AG_NAME"
```

## Portal solution (step-by-step)
### 1) Create resource group for monitor resources
1. Open Resource groups and create ${RG_NAME} in ${LOCATION}.

### 2) Create Action Group
1. Open Monitor.
2. Select Alerts > Action groups > Create.
3. In Basics:
  - Resource group: ${RG_NAME}
  - Action group name: ${AG_NAME}
  - Display name: m05hlth
4. In Notifications:
  - Notification type: Email/SMS/Push/Voice
  - Name: HealthOpsEmail
  - Email: your monitored inbox
5. Select Review + create, then Create.

### 3) Create Service Health alert rule
1. In Monitor, select Alerts > Create > Alert rule.
2. Scope:
  - Select your subscription (not a single resource).
3. Condition:
  - Signal type: Activity Log
  - Category: Service Health
4. Actions:
  - Select existing Action Group ${AG_NAME}.
5. Details:
  - Alert rule name: ${SERVICE_ALERT_NAME}
  - Severity: 2 or 3
  - Enable upon creation: Yes
6. Create the rule.

### 4) Create Resource Health alert rule
1. Repeat Create alert rule.
2. Scope:
  - Same subscription.
3. Condition:
  - Signal type: Activity Log
  - Category: Resource Health
4. Actions:
  - Reuse Action Group ${AG_NAME}.
5. Details:
  - Alert rule name: ${RESOURCE_ALERT_NAME}
  - Enable upon creation: Yes
6. Create the rule.

### 5) Validate
1. Open Monitor > Alerts > Alert rules.
2. Confirm both alert rules are enabled.
3. Open each rule and verify:
  - Scope is the subscription.
  - Category is correct (Service Health or Resource Health).
  - Action Group ${AG_NAME} is attached.

## Cleanup (required)
```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env
echo "Cleanup started: $RG_NAME"
```

## Notes
- Service/Resource Health alerts fire only when matching platform events occur.
- Keep one standardized Action Group for shared operational visibility.
