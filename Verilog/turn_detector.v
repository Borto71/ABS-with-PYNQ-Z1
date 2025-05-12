module SteeringDirection (
    input wire [15:0] wheel_speed_fl, // Velocità ruota anteriore sinistra
    input wire [15:0] wheel_speed_fr, // Velocità ruota anteriore destra
    input wire [15:0] wheel_speed_rl, // Velocità ruota posteriore sinistra
    input wire [15:0] wheel_speed_rr, // Velocità ruota posteriore destra
    output reg [1:0] direction // 00 = dritto, 01 = sinistra, 10 = destra
);

    reg [15:0] avg_left;
    reg [15:0] avg_right;

    always @(*) begin
        // Calcola la velocità media delle ruote sinistre e destre
        avg_left  = (wheel_speed_fl + wheel_speed_rl) >> 1; // velocità media ruote di sinistra
        avg_right = (wheel_speed_fr + wheel_speed_rr) >> 1; // velocità media ruote di destra

        // Determina la direzione
        if (avg_left > avg_right)
            direction = 2'b10; // Sterzata a destra
        else if (avg_right > avg_left)
            direction = 2'b01; // Sterzata a sinistra
        else
            direction = 2'b00; // Dritto
    end

endmodule
