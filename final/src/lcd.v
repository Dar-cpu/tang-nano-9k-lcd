module VGAMod
(
    input                   CLK,
    input                   nRST,
    input                   PixelClk,
    output                  LCD_DE,
    output                  LCD_HSYNC,
    output                  LCD_VSYNC,
    output          [4:0]   LCD_B,
    output          [5:0]   LCD_G,
    output          [4:0]   LCD_R
);

// Parámetros de pantalla
localparam      H_Area = 16'd1024; // Pixeles en horizontal   
localparam      V_Area = 16'd545;  // Pixeles en vertical    
 
localparam      H_Pulse      = 16'd1;
localparam      H_FrontPorch = 16'd210;
localparam      H_BackPorch  = 16'd46;
localparam      V_Pulse      = 16'd4;
localparam      V_FrontPorch = 16'd19;
localparam      V_BackPorch  = 16'd20;

localparam      PixelForHS  =   H_Pulse + H_FrontPorch + H_Area + H_BackPorch;
localparam      LineForVS   =   V_Pulse + V_FrontPorch + V_Area + V_BackPorch;

localparam      PixelStartData = H_Pulse + H_FrontPorch;
localparam      PixelEndData   = PixelStartData + H_Area;
localparam      LineStartData  = V_Pulse + V_FrontPorch;
localparam      LineEndData    = LineStartData + V_Area;

// Parámetros de imagen 
localparam      IMG_WIDTH  = 16'd200;  // Ancho de imagen
localparam      IMG_HEIGHT = 16'd138;  // Alto de imagen

reg [15:0] LineCount;
reg [15:0] PixelCount;
reg [14:0] SDRAMAddr;
reg [14:0] SDRAMAddr_next;

// Variables para cálculo de coordenadas
reg [15:0] display_x, display_y;
reg [15:0] img_x, img_y;

// Contadores de píxeles y líneas
always @(posedge PixelClk or negedge nRST) begin
    if (!nRST) begin
        LineCount  <= 16'b0;    
        PixelCount <= 16'b0;
    end else begin   
        if (PixelCount == PixelForHS - 1) begin
            PixelCount <= 16'b0;
            if (LineCount == LineForVS - 1) begin
                LineCount <= 16'b0;
            end else begin
                LineCount <= LineCount + 1'b1;
            end
        end else begin             
            PixelCount <= PixelCount + 1'b1;    
        end              
    end
end

// Cálculo de dirección de memoria - ESCALADO DIRECTO
always @(*) begin
    // Coordenadas relativas en el área de display
    display_x = PixelCount - PixelStartData;
    display_y = LineCount - LineStartData;
    
    // Verificar que estamos dentro del área válida de display
    if (display_x < H_Area && display_y < V_Area) begin
        // Escalado directo: cada píxel de imagen se mapea a múltiples píxeles de pantalla
        // 800/200 = 4, 480/118 ≈ 4.07
        img_x = (display_x * 200) >> 10;  // divide por 4 (800/200)
        img_y = (display_y * IMG_HEIGHT) / V_Area;  // escalado vertical más preciso
        
        // Asegurar que no excedamos los límites de la imagen
        if (img_x >= IMG_WIDTH) img_x = IMG_WIDTH - 1;
        if (img_y >= IMG_HEIGHT) img_y = IMG_HEIGHT - 1;
        
        // Dirección lineal en memoria
        SDRAMAddr_next = (img_y * IMG_WIDTH) + img_x;
    end else begin
        SDRAMAddr_next = 15'b0;
    end
end

// Registro de dirección para sincronización
always @(posedge PixelClk or negedge nRST) begin
    if (!nRST) begin
        SDRAMAddr <= 15'b0;
    end else begin
        SDRAMAddr <= SDRAMAddr_next;
    end
end

// Señales de sincronización
assign LCD_HSYNC = PixelCount >= H_Pulse;
assign LCD_VSYNC = LineCount >= V_Pulse;
assign LCD_DE = (PixelCount >= PixelStartData) && (PixelCount < PixelEndData) && 
                (LineCount >= LineStartData) && (LineCount < LineEndData);

// Instancia de memoria
wire [15:0] SDRAMOut;
Gowin_SP SDRAMInstance(
    .dout(SDRAMOut),     // output [15:0] dout
    .clk(PixelClk),      // input clk
    .oce(1'b1),          // input oce
    .ce(1'b1),           // input ce
    .reset(~nRST),       // input reset
    .wre(1'b0),          // input wre
    .ad(SDRAMAddr),      // input [14:0] ad
    .din(16'b0)          // input [15:0] din
);

// Salida RGB (formato RGB565) - Solo cuando estamos en área válida
wire [15:0] pixel_data;
assign pixel_data = (display_x < H_Area && display_y < V_Area) ? SDRAMOut : 16'h0000;

assign LCD_R = pixel_data[15:11];
assign LCD_G = pixel_data[10:5];
assign LCD_B = pixel_data[4:0];

endmodule