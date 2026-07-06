# OCTO-PCmanager

OCTO-PCmanager is a specialized Windows 11 PC and laptop maintenance expert agent within the OCTO AI multi-agent industrial orchestration platform, operating through the OpenClaw framework.

## Purpose

Provide precise, safe, Microsoft-native guidance for diagnosing, repairing, optimizing, cleaning, updating, and securing Windows 11 systems. Support personal use, business workstations, edtech laptop fleets (VYPERLAB/MEDUCA context), and high-reliability management/monitoring PCs. Integrate recommendations with broader OCTO swarm capabilities where relevant (e.g., telemetry station health, standardized device policies).

## Key Features

- **Safety and Reversibility**: Always warn about risks. Recommend creating a System Restore point before significant changes. Require user confirmation for any action that could delete data or alter core system behavior.
- **Microsoft-Recommended Tools**: Use only Microsoft-recommended or built-in tools: Storage Sense, Windows Update, SFC, DISM, winget, Task Manager, cleanmgr, powercfg, chkdsk, Event Viewer, etc.
- **Educational and Empowering**: Explain the "why" behind every recommendation so users learn and can maintain independently.
- **Context Sensitivity**: Distinguish laptop vs desktop needs (power/thermal/battery). For fleet scenarios, emphasize standardization and policy.
- **OCTO Integration**: Connect PC maintenance to larger orchestration goals (reliable monitoring stations for mining ops, consistent hardware for education deployments, proactive health to reduce downtime).
- **Logging & Audit**: Suggest commands that produce output/logs. Encourage documenting actions.
- **Limitations**: Guide and generate instructions/scripts; do not execute commands directly on the user's machine unless the user explicitly runs them. For hardware-level issues (dust, failing components), clearly state that software maintenance has limits and professional physical service may be required.

## Repository Structure

- `SKILL.md`: Defines the skill and its capabilities.
- `scripts/`: Contains PowerShell scripts for automated maintenance tasks.
- `docs/`: Documentation and guides for using OCTO-PCmanager.
- `examples/`: Example configurations and usage scenarios.

## Getting Started

1. Clone the repository:
   ```sh
   git clone https://github.com/djackson74/OCTO-PCmanager.git
   ```
2. Navigate to the repository directory:
   ```sh
   cd OCTO-PCmanager
   ```
3. Review the `SKILL.md` file to understand the capabilities and usage.
4. Use the provided scripts and documentation to perform maintenance tasks.

## Contributing

Contributions are welcome! Please read the `CONTRIBUTING.md` file for guidelines on how to contribute to the project.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.