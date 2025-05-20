# **ABS-with-PYNQ-Z1**
This project implements an **Anti-lock Braking System** (ABS) on the **PYNQ-Z1** FPGA development board. The ABS logic is written in Verilog and synthesized using Xilinx Vivado. The final bitstream is generated and deployed through the Vivado design suite.

## **GOAL OF THE PROJECT**
The goal of this project was to design an ABS (Anti-lock Braking System) in Verilog, simulate it, and test its functionality.

## **SYSTEM EXPLANATION**

The ABS (Anti-lock Braking System) operates by continuously monitoring both the wheel speed and the
overall vehicle speed. Using these inputs, the system calculates the slip ratio (slip percentage), based on known
physical formulas. When the slip exceeds a predefined threshold—signaling a potential wheel lock-up—the
system initiates corrective measures to maintain traction and avoid skidding.
Upon detecting a lock-up condition, the system performs the following actions:
1. Closure of the Vrc1 electro-valve: This prevents the driver from increasing brake pressure on the
affected wheel, effectively isolating the wheel from additional hydraulic pressure input.
2. Opening of the Vrc2 electro-valve: This valve, which remains closed under normal braking conditions,
is opened to recover brake fluid from the main caliber circuit. The reduction in pressure on the wheel
helps to reduce the braking power and restore the wheels rotation.
3. Brake fluid handling: In a conventional ABS design, the recovered fluid would be temporarily stored
in an expansion vessel located near the Vrc2 valve. However, for simplification purposes in this implementation,
the expansion vessel is omitted. Instead, the system directly activates a recovery pump, which
reroutes the brake fluid back into the main hydraulic circuit over the Vrc1, just after the brake pedal.
This ensures that brake pressure could be restored promptly once the slip condition is resolved

## **OBTAINED RESULT**

To ensure comprehensive validation of the ABS system, I developed and used two different versions of the
testbench, each targeting specific braking scenarios.
In the first testbench (Testbench ABS V1.v), the focus was on evaluating the ABS behavior under basic and
moderately complex conditions. This version simulated two primary cases:
Braking with no steering: The vehicle is moving straight, and the ABS logic is expected to react only to
changes in wheel slip without any directional compensation.
Braking while steering to the right: In this scenario, the testbench simulates a right turn during braking.
This allows us to verify the integration between the turn detector and direction compensator modules, ensuring
that the system correctly adjusts the slip offset and tolerates higher slip values on the appropriate wheels.
These scenarios allowed for effective validation of the basic EFSM transitions, slip detection, and the initial
interaction of directional logic with the core ABS system.

The outputs obtained from the first simulation were fully consistent with the expected behavior of a typical
ABS system under test conditions. Based on these promising results, I proceeded to run a second testbench,
Testbench ABS V2.v, which provided a new set of input stimuli.
This version focused on testing the ABS response during braking while the vehicle was steering to the left,
allowing further validation of the system’s ability to adapt slip tolerance based on turning direction.
These additional tests helped confirm the robustness and adaptability of the implemented ABS logic under
varied dynamic scenarios.

## **REFERENCE**

[1] TEXA EDU, Introduzione ai sistemi ABS, Dispense didattiche, 2024.

[2] Corso FPGA – Universit`a di Verona, Prof. Luigi Capogrosso, Anno accademico 2024/2025.

[3] Gianluca Bortolaso, Supporto e chiarimenti sul funzionamento dell’ABS, discussioni personali, 2025.
