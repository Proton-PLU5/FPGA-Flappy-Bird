# Flappy Boss
## A VHDL-Based Embedded Game System on DE0-CV FPGA

---

## Project Overview

<div align="center">

# Flappy Boss

</div>

<div align="center">
  
<img width="480" height="270" alt="GIF_Flappy Boss Clip 1" src="https://github.com/user-attachments/assets/c51ee61b-43b1-41f0-ba59-18840617e752"/>

</div>

<div align="center">

*A real-time game implemented on an Altera Cyclone V FPGA (DE0-CV board) using VHDL.*

</div>

*More footage below!*

## Team

*Mathew Cibi, Jerry Luo, Lachlan Henderson*

## Key Technical Features

### **VGA Controller Logic**
Custom-built video driver managing exact pixel-generation timing for 640×480 @ 60Hz output. The controller:
- Generates precise H-Sync (horizontal synchronisation) and V-Sync (vertical synchronisation) signals per VGA specification
- Tracks active pixel coordinates in real-time to enable direct sprite rendering
- Eliminates the need for external frame buffers by computing pixel values on-the-fly
- Delivers deterministic latency between game state update and pixel output

### **Synchronous Sequential Logic**
All game logic runs on a master clock divided into appropriate frequency domains:
- **Game State Machine (FSM)**: Manages game modes (idle, playing, game-over) with clean state transitions
- **Collision Detection Engine**: Hardware-implemented bounding-box collision routines running every cycle
- **Physics Engine**: Real-time position updates, velocity calculations, and gravity application
- **Input Handler**: Debounced button input driving game state changes

### **On-the-Fly Video Generation**
Optimised hardware rendering eliminates frame buffer storage:
- Sprites (bird, obstacles, terrain) are computed directly from VGA scan coordinates
- ROM-based lookup tables store sprite geometry and background patterns
- Multiplexed pixel data selection based on active display region
- Efficient memory utilization allowing larger sprite sets and visual complexity

### **Modular Clock Domain Management**
Multiple clock dividers ensure synchronisation across subsystems:
- Master PLL input clock (50 MHz)
- VGA pixel clock (25.175 MHz for 640×480 @ 60Hz)
- Game logic clock (configurable for gameplay speed)
- Debounce clock for input sampling

## System Architecture

The project is decomposed into modular, reusable hardware components centred around gameplay flow, rendering, and timing control:

- **Level Controllers**: Manage stage progression, resets, and transitions between gameplay states
- **Sprite Renderers**: Translate game objects into visible VGA output using scan-coordinate-based rendering
- **Obstacle Generation**: Uses LFSR-driven logic to produce varied obstacle sequences and replayable gameplay patterns
- **Game Logic Core**: Coordinates scoring, level switching, restart behaviour, and object state updates
- **Display Pipeline**: Converts internal game state into real-time VGA signals without a full frame buffer
- **Clock and Sync Logic**: Keeps the rendering and gameplay paths aligned with the FPGA timing domains

**Component Integration**:
- All modules communicate via synchronous signals to prevent glitches and preserve deterministic behaviour
- Centralised clock distribution ensures the game logic, obstacle updates, and display output remain aligned
- Renderer modules consume the current level state and active scan position to decide each pixel in real time
- ROM-backed assets and generated obstacle data are combined directly in the output path

## Tools & Technologies

| Category | Technology |
|----------|-----------|
| **FPGA Platform** | Altera/Intel Cyclone V (DE0-CV Board) |
| **Hardware Description** | VHDL (IEEE 1076) |
| **Design Environment** | Quartus Prime (Synthesis, Place & Route) |
| **Simulation & Verification** | ModelSim (Testbench simulation, waveform analysis) |
| **Version Control** | Git (team collaboration) |
| **Development Host** | Windows / Linux |

## Hardware Specifications

- **Target Device**: Cyclone V (5CEBA4F23C7)
- **Display Output**: VGA 640×480 @ 60Hz (3.2" DE0-CV onboard connector)
- **Input**: Debounced push buttons (2–4 game controls)
- **Clock Source**: 50 MHz onboard oscillator (25MHz VGA Clock using PLL)
- **Memory**: Dual-port on-chip RAM for sprite ROMs; distributed RAM for pixel buffers

## Project Highlights

**Deterministic Real-Time Performance** — Game logic, rendering, and obstacle updates run directly in hardware with no software overhead  
**Modular Level Design** — Separate level and renderer modules made the system easier to extend and integrate  
**Hardware Sprite Rendering** — Objects are drawn directly from scan coordinates, avoiding a full frame buffer  
**Procedural Obstacle Generation** — LFSR-based generation creates repeatable but varied gameplay sequences  
**Clean Game Flow Control** — Level switching, resetting, and state transitions are handled explicitly in the control logic  
**Team-Oriented Integration** — Clear module boundaries supported parallel development and easier system testing  

## My Individual Contributions

- **Modular System**: Designed the modular system for developing different Levels, renderers, and ensuring easy future development.
- **Sprite Renderers**: Implemented the sprite rendering component of the project.
- **Level Design & Development**: Developed the main flow of the levels, and designed LFSR and Obstacle Generation.
- **Game Logic**: Developed the level switching, resetting and flow of the game.

## Extra Footage

https://github.com/user-attachments/assets/192606bb-2fae-4452-a2fc-4d68435b96eb

https://github.com/user-attachments/assets/efbd71ee-6aef-43e1-8937-db9f9081356d

https://github.com/user-attachments/assets/4f5f4789-cd3a-482e-8b36-5141b8667c3f

https://github.com/user-attachments/assets/f3bb89d0-21e7-4e68-9601-031b4d7c18ac
