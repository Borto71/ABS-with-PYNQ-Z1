`timescale 1ns / 1ps

module EFSM_ABS_System(
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] wheel_speed,
    input  wire [7:0] vehicle_speed,
    input  wire [1:0] direction,     // 00=dritto, 01=sinistra, 10=destra
    input  wire       brake_signal,
    input  wire       accelerometer,  // 1 = forte decelerazione
    input  wire       engine_status,
    output reg        Vrc1,
    output reg        Vrc2,
    output reg        recovery_pump
);

    // FSM states
    localparam NORMAL_OPERATION   = 2'b00;
    localparam ANTILOCKING        = 2'b01;
    localparam RELEASE_PRESSURE   = 2'b10;
    localparam REAPPLY_PRESSURE   = 2'b11;

    // Slip thresholds (percentuale, intero 0..100)
    localparam SLIP_ENTER = 20; // entri in ANTILOCKING se slip > 20%
    localparam SLIP_EXIT  = 10; // esci da ANTILOCKING se slip < 10%

    // Durata minima in ANTILOCKING
    localparam MIN_ANTILOCKING_TIME = 3;

    reg [1:0]  current_state, next_state;
    reg [2:0]  antislip_counter;   // conta cicli in ANTILOCKING
    reg [7:0]  slip_pct;           // slip percentuale

    // Calcolo percentuale di slittamento (0 se wheel_speed >= vehicle_speed o vs==0)
    always @(*) begin
        if (vehicle_speed != 0 && wheel_speed < vehicle_speed) begin
            slip_pct = ((vehicle_speed - wheel_speed) * 100) / vehicle_speed;
        end else begin
            slip_pct = 0;
        end
    end

    // ----------------------------
    // 1) Registro di stato + contatore
    // ----------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state    <= NORMAL_OPERATION;
            antislip_counter <= 0;
        end else begin
            // Avanzamento stato
            current_state <= next_state;

            // Conta i cicli in ANTILOCKING
            if (current_state == ANTILOCKING)
                antislip_counter <= antislip_counter + 1;
            else
                antislip_counter <= 0;
        end
    end

    // ----------------------------
    // 2) Logica combinatoria per transizioni
    // ----------------------------
    always @(*) begin
        // default next_state
        next_state = current_state;

        case (current_state)
            NORMAL_OPERATION: begin
                if (engine_status
                    && brake_signal
                    && vehicle_speed > 8'd5
                    && slip_pct > SLIP_ENTER
                ) begin
                    next_state = ANTILOCKING;
                end
            end

            ANTILOCKING: begin
                // rimango almeno MIN_ANTILOCKING_TIME cicli e poi esco se slip basso
                if ((antislip_counter >= MIN_ANTILOCKING_TIME) 
                    && (slip_pct < SLIP_EXIT)
                ) begin
                    next_state = RELEASE_PRESSURE;
                end
            end

            RELEASE_PRESSURE: begin
                // in RELEASE_PRESSURE scarico valvola 2
                // se ancora slip alto, torno in ANTILOCKING, altrimenti vado a REAPPLY
                if ( (slip_pct > SLIP_ENTER) 
                     || accelerometer
                     || (antislip_counter > 7)
                   ) begin
                    next_state = ANTILOCKING;
                end else begin
                    next_state = REAPPLY_PRESSURE;
                end
            end

            REAPPLY_PRESSURE: begin
                // riapplico pressione finché slip basso
                if (slip_pct < SLIP_EXIT && !brake_signal) begin
                    next_state = NORMAL_OPERATION;
                end else if (slip_pct > SLIP_ENTER) begin
                    next_state = ANTILOCKING;
                end
            end
        endcase
    end

    // ----------------------------
    // 3) Uscite in base allo stato
    // ----------------------------
    always @(*) begin
        // default outputs
        Vrc1         = 1'b1;
        Vrc2         = 1'b0;
        recovery_pump= 1'b0;

        case (current_state)
            NORMAL_OPERATION: begin
                // tutto normale
            end

            ANTILOCKING: begin
                Vrc1 = 1'b0;        // chiudo valvola 1
                Vrc2 = 1'b1;        // apro valvola 2
                recovery_pump = 1'b1;
            end

            RELEASE_PRESSURE: begin
                Vrc2 = 1'b1;        // mantengo scarico pressione
            end

            REAPPLY_PRESSURE: begin
                Vrc1 = 1'b1;        // riapplico pressione
                Vrc2 = 1'b0;
                recovery_pump = 1'b0;
            end
        endcase
    end

endmodule
