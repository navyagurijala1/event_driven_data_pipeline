Event Driven Data Pipeline for User Activity Tracking
This project implements a real-time, serverless event-driven data pipeline on AWS using Terraform and Python. It demonstrates how raw user activity events can be ingested, orchestrated, processed, stored, monitored, and secured in the cloud with near real-time responsiveness.

Overview
An Event-Driven Data Pipeline is a continuous system that reacts to incoming events, applies lightweight transformation, and delivers curated outputs. This project simulates user activity (e.g., page views, clicks) flowing through a three-step workflow coordinated by AWS Step Functions.
The pipeline covers the full lifecycle of user events:
Client Event JSON → Step Functions → Lambda (Ingest → Process → Write) → S3 (Raw) → DynamoDB (Processed) → CloudWatch → IAM Security

Architecture & Key Components
Data Ingestion (Lambda + S3)
•	Accepts a user activity JSON payload and writes an immutable raw copy to s3:///ingest/yyyy=YYYY/…
•	Preserves original data for audit and replay.

Orchestration (AWS Step Functions)
•	Coordinates three Lambda tasks: Ingest → Process → Write.
•	Manages task inputs/outputs, captures execution history, and enables retries.
Data Processing (Lambda)
•	Reads the raw object from S3, validates and enriches fields (e.g., adds processed_at, normalizes action).
•	Emits a curated list of items ready for storage.

Data Storage (S3 + DynamoDB)
•	Raw Layer (S3): authoritative landing zone for original payloads.
•	Processed Layer (DynamoDB): query-ready records using PK = user_id, SK = event_time with PAY_PER_REQUEST billing.

Monitoring (CloudWatch)
•	Centralized logs for all Lambdas and the state machine.
•	Alarms on Lambda Errors and Step Functions Executions failed with optional SNS notifications.

Security (IAM Policies & Roles)
•	Least-privilege roles per Lambda:
o	Ingest: s3:PutObject to the ingest prefix only.
o	Process: s3:GetObject from the ingest prefix only.
o	Writer: dynamodb:PutItem/BatchWriteItem on the target table only.

•	Step Functions role limited to invoking these Lambdas and writing logs to CloudWatch.

Project Highlights
Near Real-Time: Micro-batch execution via state machine tasks.
Observability: Execution history, centralized logs, and alarms by default.
Security: Scoped IAM roles; S3 encryption, versioning, and public access blocked.
Scalability: Serverless components scale automatically with demand.
Repeatability: Full infrastructure is managed with Terraform (no console clicks).
Architecture Diagram
Flow: Client Event → Step Functions → Ingest (Lambda) → S3 Raw → Process (Lambda) → Writer (Lambda) → DynamoDB → CloudWatch → IAM Security

Setup & Deployment
1.	Prerequisites
•	AWS CLI with permissions to create S3, Lambda, Step Functions, DynamoDB, CloudWatch, and IAM.
•	Terraform (>= 1.5) and Python 3.11 installed locally.
2.	Infrastructure Provisioning
•	From the project root, run Terraform to create S3, DynamoDB, IAM roles, Lambdas, Step Functions, and CloudWatch resources.
3.	Test Event Preparation
•	Provide a sample event JSON representing a user action (e.g., page_view with basic metadata) in the tests folder.
4.	Trigger a Workflow Execution
•	Start a Step Functions execution using the sample event as input to drive the pipeline end-to-end.
5.	Monitor Pipeline
•	Review the Step Functions execution graph and task logs in CloudWatch.
•	Verify alarms remain OK; investigate any triggered alerts.
6.	Validate Outputs
•	Confirm the raw object in the S3 ingest prefix and the curated record(s) in the DynamoDB table.

Challenges & Lessons Learned
IAM Design: Tuning least-privilege policies for Lambda and Step Functions without breaking logging or invocation.
Logging Access: Ensuring Step Functions has CloudWatch log-delivery permissions for its log destination.
Path & Packaging: Aligning Terraform archive paths with the repository layout for Lambda packaging.
Provider/Lock Compatibility: Resolving provider version constraints and lockfile mismatches during initialization.

Future Enhancements
•	Add API Gateway or EventBridge as an external entry point for events.
•	Introduce JSON Schema validation and idempotency keys to prevent duplicates.
•	Add catch paths and a dead-letter queue (SQS) for robust failure handling.
•	Extend analytics with Glue/Athena and add CloudWatch dashboards.

License & Acknowledgments
This project is licensed under the MIT License.
Developed as part of an Event-Driven Data Pipeline assignment demonstrating serverless orchestration, data integrity, and operational visibility.

