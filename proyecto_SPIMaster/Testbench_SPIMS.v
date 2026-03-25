`timescale 1ns / 1ps

module spi_tb();

    // Señales de prueba (Entradas = reg, Salidas = wire)
    reg  tb_clk;                 // Reloj simulado
    reg  tb_rst_n;               // Reset simulado
    reg  tb_start;               // Botón inicio simulado
    reg  [7:0] tb_master_data_in;// Dato a enviar simulado
    
    wire tb_master_done;         // LED fin transmisión
    wire [7:0] tb_master_data_out; // Dato recibido por Maestro
    wire [7:0] tb_slave_data_out;  // Dato recibido por Esclavo

    // Instancia del Módulo Top (UUT)
    spi_top uut (
        .clk             (tb_clk),
        .rst_n           (tb_rst_n),
        .start           (tb_start),
        .master_data_in  (tb_master_data_in),
        .master_done     (tb_master_done),
        .master_data_out (tb_master_data_out),
        .slave_data_out  (tb_slave_data_out)
    );

    // Generador de Reloj (Periodo = 10ns)
    always #5 tb_clk = ~tb_clk;

    // Bloque de Estímulos
    initial begin
        // Valores iniciales
        tb_clk = 0;
        tb_rst_n = 0;
        tb_start = 0;
        tb_master_data_in = 8'h00;

        // Caso 1: Reinicio (Reset)
        #20 tb_rst_n = 0; // Activa reset
        #20 tb_rst_n = 1; // Libera reset (IDLE)
        #20;

        // Caso 2: Envío de primer byte (10100101)
        tb_master_data_in = 8'hA5; // Carga dato
        tb_start = 1;              // Presiona start
        #10 tb_start = 0;          // Suelta start

        wait(tb_master_done == 1'b1); // Espera a que termine
        #50;

        // Caso 3: Envío de segundo byte (00111100)
        tb_master_data_in = 8'h3C; // Carga nuevo dato
        tb_start = 1;              // Presiona start
        #10 tb_start = 0;          // Suelta start

        wait(tb_master_done == 1'b1); // Espera a que termine
        #50;

        $finish; // Termina simulación
    end

endmodule