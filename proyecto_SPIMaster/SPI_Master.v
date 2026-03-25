// Módulo Maestro
module master (
    input  wire clk,          // Reloj del sistema
    input  wire rst_n,        // Reset asíncrono
    input  wire start,        // Pulso de inicio
    input  wire [7:0] tx_data,// Dato a enviar
    output reg  sclk,         // Reloj SPI
    output reg  ss_n,         // Selector de esclavo
    output reg  mosi,         // Salida de datos
    input  wire miso,         // Entrada de datos
    output reg  done,         // Bandera de fin
    output reg [7:0] rx_data  // Dato recibido
);

    // Estados de la FSM
    localparam IDLE  = 2'b00; // Reposo
    localparam SETUP = 2'b01; // Preparación
    localparam TRANS = 2'b10; // Transmisión
    localparam DONE  = 2'b11; // Terminado

    // Registros internos
    reg [1:0] state;         // Estado actual
    reg [2:0] bit_cnt;       // Contador de bits
    reg [7:0] shift_reg_tx;  // Registro de envío
    reg [7:0] shift_reg_rx;  // Registro de recepción

    // Lógica secuencial y FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Valores por defecto en reset
            state        <= IDLE;
            sclk         <= 1'b0;
            ss_n         <= 1'b1;
            mosi         <= 1'b0;
            done         <= 1'b0;
            bit_cnt      <= 3'd0;
            shift_reg_tx <= 8'h00;
            shift_reg_rx <= 8'h00;
            rx_data      <= 8'h00;
        end else begin
            case (state)
                IDLE: begin // Espera orden de inicio
                    ss_n <= 1'b1;
                    sclk <= 1'b0;
                    done <= 1'b0;
                    if (start) begin
                        shift_reg_tx <= tx_data; // Carga dato
                        state        <= SETUP;
                    end
                end
                
                SETUP: begin // Activa esclavo y prepara MSB
                    ss_n    <= 1'b0;
                    mosi    <= shift_reg_tx[7];
                    bit_cnt <= 3'd0;
                    state   <= TRANS;
                end
                
                TRANS: begin // Alterna reloj y mueve datos
                    sclk <= ~sclk;
                    if (~sclk) begin
                        // Lee bit del esclavo
                        shift_reg_rx <= {shift_reg_rx[6:0], miso};
                    end else begin
                        // Envía siguiente bit
                        shift_reg_tx <= {shift_reg_tx[6:0], 1'b0};
                        mosi         <= shift_reg_tx[7];
                        bit_cnt      <= bit_cnt + 1'b1;
                        if (bit_cnt == 3'd7) begin
                            state <= DONE; // Termina tras 8 bits
                        end
                    end
                end
                
                DONE: begin // Finaliza comunicación
                    sclk    <= 1'b0;
                    ss_n    <= 1'b1;
                    done    <= 1'b1;
                    rx_data <= shift_reg_rx; // Guarda byte recibido
                    state   <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule

// Módulo Esclavo (Slave)
module slave (
    input  wire sclk,         // Reloj del maestro
    input  wire ss_n,         // Selector del maestro
    input  wire mosi,         // Entrada de datos
    output reg  miso,         // Salida de datos
    output reg [7:0] rx_data  // Dato recibido
);

    // Registros internos
    reg [2:0] bit_cnt;       // Contador de bits
    reg [7:0] shift_reg;     // Registro de desplazamiento

    // Captura de datos (MOSI)
    always @(posedge sclk or posedge ss_n) begin
        if (ss_n) begin
            bit_cnt   <= 3'd0;
            shift_reg <= 8'h00;
        end else begin
            shift_reg <= {shift_reg[6:0], mosi}; // Desplaza y guarda bit
            bit_cnt   <= bit_cnt + 1'b1;
            if (bit_cnt == 3'd7) begin
                rx_data <= {shift_reg[6:0], mosi}; // Guarda byte completo
            end
        end
    end

    // Envío de datos (MISO)
    always @(negedge sclk or posedge ss_n) begin
        if (ss_n) begin
            miso <= 1'b0; // Reposo
        end else begin
            miso <= shift_reg[7]; // Envía MSB
        end
    end
endmodule

// Módulo Top (Interconexión)
module spi_top (
    // Entradas/Salidas físicas
    input  wire clk,                  // Reloj FPGA
    input  wire rst_n,                // Botón reset
    input  wire start,                // Botón inicio
    input  wire [7:0] master_data_in, // Dato a enviar
    output wire master_done,          // LED fin de transmisión
    output wire [7:0] master_data_out,// LEDs dato maestro
    output wire [7:0] slave_data_out  // LEDs dato esclavo
);

    // Cables internos de conexión
    wire spi_sclk; // Reloj SPI
    wire spi_ss;   // Selector
    wire spi_mosi; // Línea MOSI
    wire spi_miso; // Línea MISO

    // Instancia del Maestro
    master u_master (
        .clk      (clk),
        .rst_n    (rst_n),
        .start    (start),
        .tx_data  (master_data_in),
        .sclk     (spi_sclk),
        .ss_n     (spi_ss),
        .mosi     (spi_mosi),
        .miso     (spi_miso),
        .done     (master_done),
        .rx_data  (master_data_out)
    );

    // Instancia del Esclavo
    slave u_slave (
        .sclk     (spi_sclk),
        .ss_n     (spi_ss),
        .mosi     (spi_mosi),
        .miso     (spi_miso),
        .rx_data  (slave_data_out)
    );

endmodule