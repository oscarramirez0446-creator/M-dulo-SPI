`timescale 1ns / 1ps // Escala de tiempo para simulación: 1 unidad = 1ns, precisión = 1ps

module spi_tb();

    // 1. Declaración de señales de prueba
    // 'reg' se usa para señales que nosotros controlamos (Entradas al módulo)
    reg  tb_clk;                 // Simula el oscilador físico de la FPGA
    reg  tb_rst_n;               // Simula el botón físico de reset
    reg  tb_start;               // Simula el botón físico para iniciar transmisión
    reg  [7:0] tb_master_data_in;// Simula 8 switches físicos con el dato a enviar
    
    // 'wire' se usa para leer las señales que genera el módulo (Salidas del módulo)
    wire tb_master_done;         // Simula un LED que indica fin de transmisión
    wire [7:0] tb_master_data_out; // Permite ver en gráficas qué recibió el Maestro
    wire [7:0] tb_slave_data_out;  // Permite ver en gráficas qué recibió el Esclavo

    // 2. Instancia del Módulo Top (Conectamos el código real con este entorno de prueba)
    spi_top uut (
        .clk             (tb_clk),
        .rst_n           (tb_rst_n),
        .start           (tb_start),
        .master_data_in  (tb_master_data_in),
        .master_done     (tb_master_done),
        .master_data_out (tb_master_data_out),
        .slave_data_out  (tb_slave_data_out)
    );

    // 3. Generación del Reloj
    // Invierte el valor cada 5ns de forma infinita (Crea una señal cuadrada)
    always #5 tb_clk = ~tb_clk; 

    // 4. Bloque de Estímulos (Simula las acciones del usuario paso a paso)
    initial begin
        // Valores iniciales (Tiempo = 0)
        tb_clk = 0;
        tb_rst_n = 0;
        tb_start = 0;
        tb_master_data_in = 8'h00;

        // Prueba 1: Verificación de Reset
        #20 tb_rst_n = 0; // Mantiene el reset presionado (activo en bajo) durante 20ns
        #20 tb_rst_n = 1; // Suelta el reset. El sistema entra a estado IDLE.
        #20;

        // Prueba 2: Envío del primer dato
        tb_master_data_in = 8'hA5; // Pone en los switches el valor 10100101 en binario
        tb_start = 1;              // Presiona el botón de start
        #10 tb_start = 0;          // Suelta el botón de start después de 10ns

        // Espera automática
        wait(tb_master_done == 1'b1); // Pausa el código hasta que el LED 'done' se encienda
        #50;                          // Pausa de 50ns para observar las gráficas estables

        // Prueba 3: Envío de un segundo dato
        tb_master_data_in = 8'h3C; // Cambia los switches al valor 00111100 en binario
        tb_start = 1;              // Vuelve a presionar start
        #10 tb_start = 0;          // Suelta start

        // Espera final
        wait(tb_master_done == 1'b1); // Espera a que termine la segunda transmisión
        #50;

        $finish; // Cierra la simulación de ModelSim
    end

endmoduless