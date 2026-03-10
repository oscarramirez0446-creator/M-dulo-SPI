
// Módulo Maestro
module master (
    input  wire clk,          // Reloj del sistema
    input  wire rst_n,        // Reset asíncrono (recomendado)
    input  wire start,        // Señal para iniciar transmisión
    input  wire [7:0] tx_data,// Dato a enviar
    output reg  sclk,         // Reloj SPI generado
    output reg  ss_n,         // Slave Select (activo en bajo)
    output reg  mosi,         // Master Out Slave In
    input  wire miso,         // Master In Slave Out
    output reg  done,         // Bandera de fin de transmisión
    output reg [7:0] rx_data  // Dato recibido del esclavo
);

    //Declaración de estados de la FSM
    localparam IDLE  = 2'b00;
    localparam SETUP = 2'b01;
    localparam TRANS = 2'b10;
    localparam DONE  = 2'b11;

    //Declaración de registros y señales internas
    reg [1:0] state;         // Estado actual de la FSM
    reg [2:0] bit_cnt;       // Contador para los 8 bits (0 a 7)
    reg [7:0] shift_reg_tx;  // Registro de desplazamiento de transmisión
    reg [7:0] shift_reg_rx;  // Registro de desplazamiento de recepción

endmodule

// Módulo Esclavo (Slave)
module slave (
    input  wire sclk,         // Reloj SPI (viene del maestro)
    input  wire ss_n,         // Slave Select (viene del maestro)
    input  wire mosi,         // Dato entrante (viene del maestro)
    output reg  miso,         // Dato saliente (va al maestro)
    output reg [7:0] rx_data  // Dato completo recibido
);

    // Declaración de registros y señales internas
    reg [2:0] bit_cnt;       // Contador de bits recibidos
    reg [7:0] shift_reg;     // Registro de desplazamiento interno


endmodule

// Módulo Top (Interconexión)
module spi_top (
    //Entradas/Salidas externas 
    input  wire clk,                  // Reloj principal de la tarjeta FPGA
    input  wire rst_n,                // Botón de reinicio (activo en bajo)
    input  wire start,                // Botón/Pulso para iniciar la transmisión
    input  wire [7:0] master_data_in, // Dato de 8 bits a enviar (ej. contador o switches)
    output wire master_done,          // LED que avisa cuando la transmisión terminó
    output wire [7:0] master_data_out,// Salida para ver el dato que recibió el Maestro
    output wire [7:0] slave_data_out  // Salida para ver el dato que recibió el Esclavo
);

    //Cables internos
    // conectar los pines del Maestro con los del Esclavo
    wire spi_sclk; // Transporta el reloj generado por el Maestro
    wire spi_ss;   // Transporta la señal para activar al Esclavo
    wire spi_mosi; // Transporta los datos del Maestro hacia el Esclavo
    wire spi_miso; // Transporta los datos del Esclavo hacia el Maestro

    //Instancia del Maestro
    master u_master (
        .clk      (clk),            // Se conecta al reloj de la tarjeta
        .rst_n    (rst_n),          // Se conecta al botón de reset
        .start    (start),          // Se conecta al botón de arranque
        .tx_data  (master_data_in), // Toma el dato a enviar desde el exterior
        .sclk     (spi_sclk),       // Genera el reloj y lo inyecta al cable interno
        .ss_n     (spi_ss),         // Genera el Slave Select y lo inyecta al cable
        .mosi     (spi_mosi),       // Envía los bits por este cable
        .miso     (spi_miso),       // Lee los bits que vienen por este cable
        .done     (master_done),    // Enciende el LED de finalización
        .rx_data  (master_data_out) // Muestra al exterior lo que recibió
    );

    //Instancia del Esclavo
    slave u_slave (
        .sclk     (spi_sclk), // Recibe el reloj desde el cable interno
        .ss_n     (spi_ss),   // Recibe la orden de activación
        .mosi     (spi_mosi), // Lee los bits que le manda el Maestro
        .miso     (spi_miso), // Envía sus propios bits al Maestro por aquí
        .rx_data  (slave_data_out) // Muestra al exterior el byte que logró armar
    );

endmodule