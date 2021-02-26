-- Author: Qulle 2017-11-16
-- Github: github.com/qulle/snake
-- Editor: vscode (initially emacs)
-- Compile: gnatmake ./snake.adb
-- Run: ./snake
-- Run: ./snake cheat

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Numerics.Discrete_Random;
with Ada.Command_Line;
with Ada.Unchecked_Deallocation;
with Ada.Sequential_IO;

procedure Snake is 
    C_RESET    : constant String := "[00m";
    BOLD       : constant String := "[01m";
    FC_RED     : constant String := "[31m";
    FC_GREEN   : constant String := "[32m";
    FC_YELLOW  : constant String := "[33m";
    FC_BLUE    : constant String := "[34m";
    FC_MAGENTA : constant String := "[35m";
    FC_CYAN    : constant String := "[36m";
   
    SNAKE_COLOR       : constant String := FC_GREEN;
    TARGET_COLOR      : constant String := FC_RED;
    INIT_SNAKE_LENGTH : constant Positive := 4;
   
    package BIN_IO is new Ada.Sequential_IO(Natural);
    package CL renames Ada.Command_Line;
   
    type Directions is (LEFT, RIGHT, UP, DOWN);
    type Coordinate_Type is
        record
            X_Pos : Natural;
            Y_Pos : Natural;
        end record;

    type Snake_Cell;
    type Snake_Ptr is access Snake_Cell;
   
    type Snake_Cell is
        record 
            Char : Character;
            Coordinate : Coordinate_Type;
            Next : Snake_Ptr;
        end record;

    procedure Free is new Ada.Unchecked_Deallocation(Object => Snake_Cell, Name => Snake_Ptr);
   
    type Map_Type is array(1 .. 20, 1 .. 50) of Character;
    DIRR : Directions := RIGHT;
    ALIVE : Boolean := True;

    --------------------------------------------------------------------
    -- A separate task to get arrow keys, too much input lag otherwise
    --------------------------------------------------------------------
    task KeyPress_Listener;  
    task body KeyPress_Listener is
        subtype Key_Range is Integer range 65 .. 68;
        Key : Character;
        KeyCode : Key_Range;
    begin
        loop
            for I in 1 .. 3 loop
                Get_Immediate(Key);
            end loop; 
            KeyCode := Character'Pos(Key);
     
            case KeyCode is
                when 65 => DIRR := UP;    -- 27 91 65
                when 66 => DIRR := DOWN;  -- 27 91 66
                when 67 => DIRR := RIGHT; -- 27 91 67
                when 68 => DIRR := LEFT;  -- 27 91 68
                when others => ALIVE := False;
            end case;

            exit when not ALIVE;
        end loop;
    end KeyPress_Listener;

    function Get_Random(Min, Max : in Natural) return Natural is
        subtype Rnd_Range is Integer range Min .. Max;
        package Random_Package is new Ada.Numerics.Discrete_Random(Rnd_Range);
        use Random_Package;
        G : Generator;
    begin
        Reset(G);
        return Random(G);
    end Get_Random;
   
    function Empty(Snake : in Snake_Ptr) return Boolean is
    begin
        return Snake = null;      
    end Empty;
   
    procedure Add_Last(Snake : in out Snake_Ptr; Char : in Character; Coordinate: in Coordinate_Type) is
    begin
        if Empty(Snake) then
            Snake := new Snake_Cell'(Char => Char, Coordinate => (X_Pos => Coordinate.X_Pos, Y_Pos => Coordinate.Y_Pos), Next => null);
        else
            Add_Last(Snake.Next, Char, Coordinate);
        end if;
    end Add_Last;
   
    procedure Set_Target(Target : out Coordinate_Type) is
    begin
        Target.X_Pos := Get_Random(1, 50);
        Target.Y_Pos := Get_Random(1, 20);
    end Set_Target;
   
    procedure Top_Bottom is
    begin
        Put('+');
        for I in Map_Type'Range(2) loop
            Put('-');
        end loop;
        Put_Line("+");
    end Top_Bottom;
   
    procedure Draw_Map(Map : in Map_Type; Score, Highscore : in Natural; Cheat : in Boolean) is
    begin
        Put(Ascii.Esc & BOLD & "SNAKE 2.0                                CHEAT ");
        if Cheat then
            Put_Line(" [" & Ascii.Esc & FC_GREEN & "ON" & Ascii.Esc & C_RESET & "]");
        else
            Put_Line("[" & Ascii.Esc & FC_RED & "OFF" & Ascii.Esc & C_RESET & "]");
        end if;
      
        Top_Bottom;
      
        for A in Map'Range(1) loop
            Put(Ascii.Esc & C_RESET & '|');
            for B in Map'Range(2) loop
                if Map(A, B) /= '*' then
                    Put(Ascii.Esc & BOLD & Ascii.Esc & SNAKE_COLOR & Map(A, B));
                else
                    Put(Ascii.Esc & BOLD & Ascii.Esc & TARGET_COLOR & Map(A, B));
                end if;
            end loop;
            Put_Line(Ascii.Esc & C_RESET & "|");
        end loop;
      
        Top_Bottom;
      
        Put("Your Score is: ");
        Put(Ascii.Esc & BOLD & Ascii.Esc & FC_GREEN);
        Put(Score, Width => 0);
        Put(Ascii.Esc & C_RESET);
      
        Put("                     Highscore: ");
        Put(Ascii.Esc & BOLD & Ascii.Esc & FC_GREEN);
        Put(Highscore, Width => 3);
        Put_Line(Ascii.Esc & C_RESET);
      
        if DIRR = UP or DIRR = DOWN then
            delay 0.15;
        else
            delay 0.1;
        end if;
    end Draw_Map;
   
    function Collision_Detection(Ptr : in Snake_Ptr; Coordinate : in Coordinate_Type) return Boolean is
        Snake : Snake_Ptr := Ptr;
    begin
        while not Empty(Snake) loop     
            if Snake.Coordinate = Coordinate then
                return True; -- Collision detected
            end if;
            Snake := Snake.Next;
        end loop;

        return False; -- No collision
    end Collision_Detection;
   
    function Out_Of_Bounds_Detection(Coordinate : in Coordinate_Type) return Boolean is
    begin
        if Coordinate.X_Pos > Map_Type'Length(2) or Coordinate.X_Pos < 1 or Coordinate.Y_Pos > Map_Type'Length(1) or Coordinate.Y_Pos < 1 then
            return True; -- Collision border
        end if;

        return False; -- No collision
    end Out_Of_Bounds_Detection;
   
    procedure Plot_Snake(Map : in out Map_Type; Ptr : in Snake_Ptr; Coordinate : in Coordinate_Type; Score : in out Natural; Target : in out Coordinate_Type; Cheat_Enabled : in Boolean) is
        Snake : Snake_Ptr := Ptr;
        Prev, Next : Snake_Ptr := null;
    begin
        if Out_Of_Bounds_Detection(Coordinate) or (Collision_Detection(Snake, Coordinate) and not Cheat_Enabled) then
            ALIVE := False;
            return;
        end if;

        if Coordinate = Target then
            Add_Last(Snake, '0', Coordinate => (1, 1));
            Set_Target(Target);
            Score := Score + 1;
        end if;
      
        Prev := new Snake_Cell;
        Next := new Snake_Cell;
      
        Prev.all := Snake.all;
        Snake.Coordinate := Coordinate;
        Map(Snake.Coordinate.Y_Pos, Snake.Coordinate.X_Pos) := Snake.Char;
        Snake := Snake.Next;
      
        while not Empty(Snake) loop     
            Next.all := Snake.all;
            Snake.Coordinate := Prev.Coordinate;
            Prev.all := Next.all;
            Map(Snake.Coordinate.Y_Pos, Snake.Coordinate.X_Pos) := Snake.Char;
            Snake := Snake.Next;
        end loop;
        Free(Prev);
        Free(Next);
    end Plot_Snake;
   
    function File_Exists return Boolean is 
        File : BIN_IO.File_Type;
    begin
        BIN_IO.Open(File, BIN_IO.In_File, "highscore.snake");
        BIN_IO.Close(File);
        return True;
    exception
        when Name_Error => return False;      
    end File_Exists;
   
    procedure Init(Snake : in out Snake_Ptr; Cheat_Enabled : in out Boolean; Target : out Coordinate_Type; File : in out BIN_IO.File_Type; Highscore : in out Natural) is
    begin
        if CL.Argument_Count > 0 then
            if CL.Argument(1) = "cheat" then
                Cheat_Enabled := True; -- ./snake cheat
            end if;
        end if;

        Put(Ascii.ESC & "[2J" & Ascii.Esc & "[1;1H");

        for I in reverse 0 .. INIT_SNAKE_LENGTH - 1 loop
            Add_Last(Snake, '0', Coordinate => (I, 1));
        end loop;

        Set_Target(Target);
      
        -- Load HighScore
        if File_Exists then
            BIN_IO.Open(File, BIN_IO.In_File, "highscore.snake");
            BIN_IO.Read(File, Highscore);
            BIN_IO.Close(File);
        end if;
    end Init;

    Snake : Snake_Ptr := null;
    Map : Map_Type := (others => (others => ' '));
    Coordinate : Coordinate_Type := (X_Pos => INIT_SNAKE_LENGTH, Y_Pos => 1);
    Score : Natural := 0;
    Highscore : Natural := 0;
    Game_Over_Msg : String := "GAME OVER";
    Score_Msg : String := "Your score:";
    Highscore_Msg : String := "~NEW HIGHSCORE~";
    Cheat_Enabled : Boolean := False;
    Target : Coordinate_Type;
    File : BIN_IO.File_Type;
begin
    Init(Snake, Cheat_Enabled, Target, File, Highscore);
   
    while ALIVE loop
        Map(TARGET.Y_Pos, TARGET.X_Pos) := '*';
        Plot_Snake(Map, Snake, Coordinate, Score, Target, Cheat_Enabled);
        Draw_Map(Map, Score, Highscore, Cheat_Enabled);
        Map := (others => (others => ' ')); 
        Put(Ascii.Esc & "[2J" & Ascii.Esc & "[1;1H");
      
        if ALIVE then
            case DIRR is
                when LEFT  => Coordinate.X_Pos := Coordinate.X_Pos - 1;
                when RIGHT => Coordinate.X_Pos := Coordinate.X_Pos + 1;
                when UP    => Coordinate.Y_Pos := Coordinate.Y_Pos - 1;
                when DOWN  => Coordinate.Y_Pos := Coordinate.Y_Pos + 1;
            end case;
        end if;
    end loop;
    --------------------------------------------------
    -- When not alive, snake has collided
    --------------------------------------------------
    Map := (others => (others => ' '));
   
    for I in Game_Over_Msg'Range loop
        Map(8, 20 + I) := Game_Over_Msg(I);
    end loop;

    for I in Score_Msg'Range loop
        Map(9, 18 + I) := Score_Msg(I);
    end loop;
   
    for I in Integer'Image(Score)'Range loop
        Map(9, 29 + I) := Integer'Image(Score)(I);
    end loop;
   
    if Score > Highscore then
        for I in Highscore_Msg'Range loop
            Map(11, 17 + I) := Highscore_Msg(I);
        end loop;
      
        BIN_IO.Create(File, BIN_IO.Out_File, "highscore.snake");
        BIN_IO.Write(File, Score);
        BIN_IO.Close(File);
    end if;
   
    Draw_Map(Map, Score, Highscore, Cheat_Enabled);
    Put(Ascii.Esc & C_RESET);
    Put_Line("Press any arrowkey to exit...");
end Snake;
