# Security Policy
The Roots application and its related codebases take security seriously.
This document outlines the versions we support, how to report vulnerabilities, how disclosure is handled, and what you can expect from the security response process.

⸻

# Supported Versions:
- 1.0.0: Supported	Active development branch. Receives security fixes and patches immediately.

> Security patches are backported only to actively supported versions.

⸻

# Reporting a Vulnerability

If you believe you have discovered a security vulnerability in Roots, we request that you do not disclose the issue publicly until we have assessed and resolved it.

Please report vulnerabilities through one of the following private channels:

**Primary Method (Preferred)**
**GitHub**:
Open a Private Security Advisory for the repository:
	1.	Go to the Roots GitHub repository
	2.	Click: Security → Advisories → Report a vulnerability
	3.	Fill in details and submit securely

**Alternative Method**
**Email**:
clevelandlewisiii@icloud.com

Include:
	•	A clear and concise description of the vulnerability
	•	Steps to reproduce the issue
	•	A proof-of-concept if possible
	•	Impact assessment (what could an attacker achieve?)
	•	Affected version or commit SHA
	•	Your environment (OS/version, device, build configuration)


> This creates a private thread visible only to the security maintainers.

⸻

# Security Response Process

> Once a report is received, the Roots security maintainer will begin the following workflow:

1. Acknowledgment (within 48 hours)

You will receive:
	•	A confirmation that the report has been received
	•	A tracking ID for the issue
	•	Initial triage classification (see below)

2. Initial Assessment (within 3 business days)

We determine:
	•	Whether the issue is valid
	•	The severity level
	•	Whether the issue needs immediate patching
	•	Whether the issue impacts App Store builds, downloadable builds, or both

3. Remediation Phase

**Depending on severity:**
Severity	Example Impact	Expected Timeline
Critical	RCE, data exposure, unauthorized access. Patch within 24–72 hours
High	Privilege escalation, logic bypass, Patch within 7 days
Medium	Minor leakage, limited user impact. Patch within 14–21 days
Low	Cosmetic or non-exploitable bugs, Next planned release

During remediation, you will receive updates as meaningful progress occurs (at least once per week for High/Critical issues).

4. Verification

The reporter may be asked to:
	•	Validate the patch
	•	Retest the issue
	•	Confirm that mitigation fully resolves the vulnerability

5. Disclosure

After a fix is released:
	•	A security advisory is published
	•	CVE requested when appropriate
	•	Reporter credited (unless anonymity requested)

If the issue is declined (not a vulnerability), you will receive:
	•	A detailed explanation
	•	The reasoning for classification
	•	Any recommended improvements to the report

⸻

Security Hardening Expectations for Contributors

Any pull request touching:
	•	authentication
	•	data persistence
	•	scheduling engine
	•	gradebook data
	•	iCloud sync
	•	encryption or secure storage
	•	external API usage

must include:
	•	explanation of security impact
	•	confirmation that the change does not expose sensitive data
	•	tests for failure modes whenever applicable

Changes may undergo a mandatory security review before merging.

⸻

# Out-of-Scope Vulnerabilities

The following do not qualify as reportable vulnerabilities:
	•	UI bugs with no security consequence
	•	App crashes without security impact
	•	Behavior requiring rooted/jailbroken devices
	•	Hypothetical or speculative issues with no practical exploitation path
	•	Social engineering reports
	•	Features behaving as documented

⸻

Thank You,

I greatly appreciate all responsible security researchers who help keep Roots secure.
Your work protects the stability of the application and the privacy of all end users.

⸻
