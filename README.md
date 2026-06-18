# 🌡️ FPGA I2C Temperature Reader with 7‑Segment Display
### Semester Project  
**Author:** Skileros98

## 📘 Overview
---
This project implements an FPGA‑based system that reads temperature data from an I2C sensor and displays it on an 8‑digit 7‑segment display.  
The design runs on the **Nexys A7** board and is fully written in **Verilog**.

## 🧩 System Components
---
- **I2C Master** – communicates with the temperature sensor using a 7‑state FSM
- **BCD Converter** – transforms binary temperature data into BCD format
- **7‑Segment Driver** – multiplexes digits and displays numbers + symbols (º, C)
- **Clock Dividers** – generate timing for I2C and display refresh
- **Main Module** – connects all components into a functional system

## 🔌 Data Flow
---
1. I2C master reads temperature (13 bits used)
2. Value is converted to BCD
3. Display driver shows digits on 7‑segment display 

## 🔧 Key Features
---
- Parametric modules
- Clean FSM‑based I2C logic 
- Multiplexed 7‑segment control 
- Fully synthesizable Verilog design  

