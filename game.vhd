--Equipo 5
--Auric
--Eric
--Demian
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY game IS
	GENERIC (
		Ha: INTEGER := 96; --Hpulse
		Hb: INTEGER := 144; --Hpulse+HBP
		Hc: INTEGER := 784; --Hpulse+HBP+Hactive
		Hd: INTEGER := 800; --Hpulse+HBP+Hactive+HFP
		Va: INTEGER := 2; --Vpulse
		Vb: INTEGER := 35; --Vpulse+VBP
		Vc: INTEGER := 515; --Vpulse+VBP+Vactive
		Vd: INTEGER := 525); --Vpulse+VBP+Vactive+VFP
	PORT (
		clk: IN STD_LOGIC; --50MHz in our board
		update_mode:in std_logic; --button to update the image
		sw_selector: IN STD_LOGIC_vector(9 downto 0);
		pixel_clk: BUFFER STD_LOGIC;
		Hsync, Vsync: BUFFER STD_LOGIC;
		R, G, B: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		led_bcd: out 		std_logic_vector( 6 downto 0 );
		nblanck, nsync : OUT STD_LOGIC
		);
END game;
	


ARCHITECTURE logic OF game IS
SIGNAL Hactive, Vactive, dena: STD_LOGIC;
constant counter_limit  : natural := 50000000;
signal button_sim: std_logic_vector(1 downto 0);

signal output_1a : std_logic_vector(3 downto 0);
signal output_1b : std_logic_vector(3 downto 0);

component de10lite IS
	PORT(	
		CLOCK_50	: 	IN			std_logic;
		KEY		: 	IN 		std_logic_vector( 1 DOWNTO 0 );
		SW			: 	IN 		std_logic_vector( 9 DOWNTO 0 );
		hex0     : 	out 		std_logic_vector( 6 downto 0 )
	);
END component de10lite;

begin

-------------------------------------------------------
--Part 1: CONTROL GENERATOR
-------------------------------------------------------
	--Static signals for DACs:
	nblanck <= '1'; --no direct blanking
	nsync <= '0'; --no sync on green
	--Create pixel clock (50MHz->25MHz):
	PROCESS (clk)
	BEGIN
		IF (clk'EVENT AND clk='1') THEN pixel_clk <= NOT pixel_clk;
		END IF;
	END PROCESS;
	--Horizontal signals generation:
	PROCESS (pixel_clk)
	VARIABLE Hcount: INTEGER RANGE 0 TO Hd;
	BEGIN
		IF (pixel_clk'EVENT AND pixel_clk='1') THEN Hcount := Hcount + 1;
			IF (Hcount=Ha) THEN Hsync <= '1';
			ELSIF (Hcount=Hb) THEN Hactive <= '1';
			ELSIF (Hcount=Hc) THEN Hactive <= '0';
			ELSIF (Hcount=Hd) THEN Hsync <= '0'; Hcount := 0;
			END IF;
		END IF;
	END PROCESS;
	--Vertical signals generation:
	PROCESS (Hsync)
	VARIABLE Vcount: INTEGER RANGE 0 TO Vd;
	BEGIN
		IF (Hsync'EVENT AND Hsync='0') THEN Vcount := Vcount + 1;
			IF (Vcount=Va) THEN Vsync <= '1';
			ELSIF (Vcount=Vb) THEN Vactive <= '1';
			ELSIF (Vcount=Vc) THEN Vactive <= '0';
			ELSIF (Vcount=Vd) THEN Vsync <= '0'; Vcount := 0;
			END IF;
		END IF;
	END PROCESS;
	---Display enable generation:
	dena <= Hactive AND Vactive;
	-------------------------------------------------------
	--Part 2: IMAGE GENERATOR
	-------------------------------------------------------

	PROCESS (Hsync, Vsync,Hactive, Vactive, dena)
	
	VARIABLE line_counter: INTEGER RANGE 0 TO Vc;
	Variable column_counter: integer range 0 to Hc;
	variable starting_position_x:integer range 0 to Hc:=70;
	variable starting_position_y:integer range 0 to Vc:=270;
	variable ship_position_x:integer range 0 to Hc:=70;
	variable ship_position_y:integer range 0 to Vc:=270;
	variable obstacle_pos_x:integer range 0 to Hc:=700;
	variable obstacle_pos_y:integer range 0 to Vc:=480;
	variable counter:integer range 0 to 500000;
	variable counter_time:integer range 0 to 30;
	variable y_collision_obstacle:integer range 0 to Vc:=230;
	--collision in x is obstacle_pos_x-150
	
	
					  
	
	BEGIN
		

		IF (Vsync='0') THEN
			line_counter := 0;
		ELSIF (Hsync'EVENT AND Hsync='1') THEN
			IF (Vactive='1') THEN
				line_counter := line_counter + 1;
			END IF;
		END IF;
		IF (Hsync='0') THEN
			column_counter := 0;
		ELSIF (pixel_clk'EVENT AND pixel_clk='1') THEN
			IF (Hactive='1') THEN
				column_counter := column_counter + 1;
				counter:=counter+1;
			END IF;
		END IF;
		
		IF (dena='1') THEN  --(x,y,h,w)
			
		if((line_counter<=obstacle_pos_y and (line_counter>obstacle_pos_y-250)) and (column_counter>(obstacle_pos_x-150) and column_counter<=obstacle_pos_x)) then
					R <= (OTHERS => '1');
					G <= (OTHERS => '0');
					B <= (OTHERS => '0');
			elsiF ((line_counter>= (ship_position_y-70) and line_counter<ship_position_y) and (column_counter >= (ship_position_x-50) and column_counter <= ship_position_x)) THEN
					R <= "1111";
					G <="0101";
					B <="1111";
			elsif((column_counter >=ship_position_x and column_counter <=(ship_position_x+20))) then
				if((line_counter >=(ship_position_y-55) and line_counter<=(ship_position_y-45)) or (line_counter>=(ship_position_y-25) and line_counter<=(ship_position_y-15))) then 
					R <= "1111";
					G <="0101";
					B <="1111";
				else
					R <= (OTHERS => '0');
					G <= (OTHERS => '0');
					B <= (OTHERS => '0');
			
				end if;
		
			else
				R <= (OTHERS => '0');
				G <= (OTHERS => '0');
				B <= (OTHERS => '0');
			end if;
	
					
		ELSE
			R <= (OTHERS => '0');
			G <= (OTHERS => '0');
			B <= (OTHERS => '0');
		END IF; --if dena
--		
--
--				
--			
--			--11 go up, 00 go down, 01 go left, 10 go right
--
				if (rising_edge(clk)) then
					--move obstacle
					if (counter=15000) then
						obstacle_pos_x:=obstacle_pos_x-5;
						end if;


					if (update_mode='1') then
						counter_time:=0;
						ship_position_y:=starting_position_y;
					elsif (update_mode='0' and counter_time<=25) then
						ship_position_y:=ship_position_y-2;
						counter_time:=counter_time+1;
					end if;
					

					if ((ship_position_x >= (obstacle_pos_x - 150)) and (ship_position_y > y_collision_obstacle)) then
							button_sim<="01";
					else
							button_sim<="00";

					end if;
				end if;
	END PROCESS;
	
	death_counter:de10lite port map(clk,button_sim,sw_selector,led_bcd);

END logic;
