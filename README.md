# Bitcoin Enclave Node

This project provides the Infrastructure as Code (IaC) to deploy a secure Bitcoin application node using confidential computing principles on AWS.

## 1. Problem Statement

Deploying Bitcoin infrastructure, such as full nodes, Arkade nodes, or Application Specific Processors (ASPs), into standard cloud environments presents significant security challenges. In a typical deployment, sensitive data like cryptographic signing keys and proprietary execution logic are exposed to the underlying host operating system and, by extension, to the cloud provider.

This exposure leads to two primary weaknesses:

1.  **Lack of Confidentiality:** An administrator with access to the host machine, or the cloud provider's infrastructure, could potentially inspect the memory or storage of the running virtual machine, compromising sensitive keys and logic.
2.  **Lack of Reproducibility & Integrity:** Standard, manual deployments are prone to configuration drift and make it difficult to prove that the running environment has not been tampered with.

This project aims to solve these problems by providing a secure, verifiable, and reproducible deployment model.

## 2. Architectural Goals

Based on the problem statement, we have defined three core architectural tenets:

1.  **Confidentiality:** Signing keys and sensitive business logic must be encrypted and isolated *while in use* (i.e., in memory). They must be inaccessible to the host OS and the cloud provider.
2.  **Integrity:** We must be able to cryptographically verify that the code running in the secure environment is exactly the code we intended to run, without any modification.
3.  **Reproducibility:** The entire infrastructure deployment must be defined in code to ensure predictable, repeatable, and auditable results.

## 3. High-Level Architecture

To achieve these goals, our architecture is centered around **AWS Nitro Enclaves**, managed via **Terraform** for Infrastructure as Code.

The core concept is to partition the application. The untrusted, public-facing components run on a standard EC2 instance, while the highly sensitive, key-handling components run in a completely isolated enclave.

```
+-------------------------------------------------------------------+
| AWS Cloud                                                         |
|                                                                   |
|   +-----------------------------------------------------------+   |
|   | Parent EC2 Instance (Nitro-based)                         |   |
|   |                                                           |   |
|   |   +-----------------------+       (VSOCK)       +-----------------------+   |
|   |   | Parent Application    |<====================>| Enclave Application   |   |
|   |   | (Broker/Proxy)        |                     | (Bitcoin Signer)      |   |
|   |   |                       |                     |                       |   |
|   |   | Handles networking,   |                     | - Holds private keys  |   |
|   |   | non-sensitive tasks.  |                     | - Performs signing    |   |
|   |   +-----------------------+                     +-----------------------+   |
|   |                                                 | AWS Nitro Enclave     |   |
|   |                                                 | (Isolated VM)         |   |
|   |                                                 +-----------------------+   |
|   |                                                           |   |
|   +-----------------------------------------------------------+   |
|                                                                   |
+-------------------------------------------------------------------+
```

### Core Components

*   **Parent EC2 Instance:** A standard AWS Nitro-based EC2 instance that hosts the main application and the enclave.
*   **AWS Nitro Enclave:** A hardened, minimalistic virtual machine created from the parent instance's CPU and memory resources. It has no persistent storage, no network access, no interactive access (SSH), and no access from the parent instance.
*   **Enclave Application:** The sensitive part of our workload (e.g., the Bitcoin signing logic) runs exclusively inside the enclave.
*   **Parent (Broker) Application:** A less sensitive application runs on the parent instance, handling external network requests and communicating with the enclave.
*   **VSOCK:** A secure, point-to-point communication channel that allows the Parent Application to communicate with the Enclave Application. This is the only way in or out of the enclave.
*   **Terraform:** We use Terraform to define and provision all AWS resources, including the EC2 instance, IAM roles for attestation, and security groups.
*   **Docker:** The Enclave Application is built using a Dockerfile for a consistent environment. The resulting Docker image is then converted into an Enclave Image File (`.eif`) for deployment.

### How This Architecture Solves the Problem

*   **Confidentiality:** Keys inside the enclave are protected from the parent OS and AWS. The enclave's memory cannot be inspected.
*   **Integrity:** The enclave provides a **cryptographic attestation document** containing measurements (hashes) of the software running within it. Our application can verify this document to prove the enclave's integrity before trusting it with sensitive data.
*   **Reproducibility:** Terraform and Docker provide a complete, code-based definition of the entire system, from cloud resources to the application image, ensuring consistent and auditable deployments.