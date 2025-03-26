with Ada.Text_IO; use Ada.Text_IO;
with Ada.Float_Text_IO; use Ada.Float_Text_IO;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Unbounded.Text_IO; use Ada.Strings.Unbounded.Text_IO;
with Ada.Characters.Handling; use Ada.Characters.Handling;

procedure Expression_Calculator is

   type Variable is record
      Name : Unbounded_String;
      Val  : Float;
   end record;

   Symbol_Table : array (1 .. 10) of Variable;
   Symbol_Count : Natural := 0;

   function Lookup(Name : Unbounded_String) return Float is
   begin
      for I in 1 .. Symbol_Count loop
         if Symbol_Table(I).Name = Name then
            return Symbol_Table(I).Val;
         end if;
      end loop;
      Put_Line("Error: Undefined variable '" & To_String(Name) & "'!");
      return 0.0;
   end Lookup;

   function Sanitize(Input : Unbounded_String) return Unbounded_String is
   begin
      return Trim(Input, Both);
   end Sanitize;

   function Precedence(Op : Character) return Integer is
   begin
      case Op is
         when '+' | '-' => return 1;
         when '*' | '/' => return 2;
         when others => return 0;
      end case;
   end Precedence;

   procedure Evaluate(Expression : Unbounded_String; Result : out Float; Is_OK : out Boolean) is

      type Token_Kind is (Number, Operator, LParen, RParen, Identifier);
      type Token is record
         Kind : Token_Kind;
         Num  : Float;
         Op   : Character;
         Name : Unbounded_String;
      end record;

      procedure Get_Token(S : Unbounded_String; Pos : in out Natural; T : out Token) is
         Ch : Character;
      begin
         if Pos > Length(S) then
            T := (Kind => Operator, Op => ' ', Num => 0.0, Name => Null_Unbounded_String);
            return;
         end if;
         Ch := Element(S, Pos);
         case Ch is
            when '(' =>
               T := (Kind => LParen, Op => '(', Num => 0.0, Name => Null_Unbounded_String);
               Pos := Pos + 1;
            when ')' =>
               T := (Kind => RParen, Op => ')', Num => 0.0, Name => Null_Unbounded_String);
               Pos := Pos + 1;
            when '+' | '-' | '*' | '/' =>
               T := (Kind => Operator, Op => Ch, Num => 0.0, Name => Null_Unbounded_String);
               Pos := Pos + 1;
            when 'A' .. 'Z' | 'a' .. 'z' =>
               declare
                  Start : constant Natural := Pos;
               begin
                  while Pos <= Length(S) and then (Is_Letter(Element(S, Pos)) or else Is_Digit(Element(S, Pos))) loop
                     Pos := Pos + 1;
                  end loop;
                  T := (Kind => Identifier, Name => Unbounded_Slice(S, Start, Pos - 1), Num => 0.0, Op => ' ');
               end;
            when '0' .. '9' | '.' =>
               declare
                  Start : constant Natural := Pos;
                  Dot : Boolean := False;
               begin
                  while Pos <= Length(S) and then (Is_Digit(Element(S, Pos)) or else (Element(S, Pos) = '.' and then not Dot)) loop
                     if Element(S, Pos) = '.' then
                        Dot := True;
                     end if;
                     Pos := Pos + 1;
                  end loop;
                  T := (Kind => Number,
                        Num => Float'Value(To_String(Unbounded_Slice(S, Start, Pos - 1))),
                        Op => ' ', Name => Null_Unbounded_String);
               end;
            when others =>
               Pos := Pos + 1;
               Get_Token(S, Pos, T);
         end case;
      end Get_Token;

      procedure To_Postfix(Infix : Unbounded_String; Postfix : in out Unbounded_String; Success : out Boolean) is
         Stack : array (1 .. 50) of Character;
         Top   : Natural := 0;
         Pos   : Natural := 1;
         Tok   : Token;
      begin
         Success := True;
         while Pos <= Length(Infix) loop
            Get_Token(Infix, Pos, Tok);
            case Tok.Kind is
               when Number =>
                  Append(Postfix, Float'Image(Tok.Num) & " ");
               when Identifier =>
                  Append(Postfix, To_String(Tok.Name) & " ");
               when LParen =>
                  Top := Top + 1;
                  Stack(Top) := '(';
               when RParen =>
                  while Top > 0 and then Stack(Top) /= '(' loop
                     Append(Postfix, Stack(Top) & " ");
                     Top := Top - 1;
                  end loop;
                  if Top = 0 then
                     Success := False;
                     return;
                  end if;
                  Top := Top - 1;
               when Operator =>
                  while Top > 0 and then Stack(Top) /= '(' and then Precedence(Stack(Top)) >= Precedence(Tok.Op) loop
                     Append(Postfix, Stack(Top) & " ");
                     Top := Top - 1;
                  end loop;
                  Top := Top + 1;
                  Stack(Top) := Tok.Op;
            end case;
         end loop;

         while Top > 0 loop
            if Stack(Top) = '(' then
               Success := False;
               return;
            end if;
            Append(Postfix, Stack(Top) & " ");
            Top := Top - 1;
         end loop;
      end To_Postfix;

      function Eval_Postfix(Expr : Unbounded_String) return Float is
         Stack : array (1 .. 50) of Float;
         Top   : Natural := 0;
         Start : Natural := 1;
         End_Pos : Natural;
         C : Character;
      begin
         while Start <= Length(Expr) loop
            End_Pos := Start;
            while End_Pos <= Length(Expr) and then Element(Expr, End_Pos) /= ' ' loop
               End_Pos := End_Pos + 1;
            end loop;

            if Start < End_Pos then
               C := Element(Expr, Start);
               case C is
                  when '+' | '-' | '*' | '/' =>
                     if Top < 2 then
                        raise Program_Error with "Too few operands";
                     end if;
                     declare
                        B : Float := Stack(Top);
                        A : Float := Stack(Top - 1);
                        R : Float;
                     begin
                        Top := Top - 2;
                        case C is
                           when '+' => R := A + B;
                           when '-' => R := A - B;
                           when '*' => R := A * B;
                           when '/' =>
                              if B = 0.0 then
                                 raise Program_Error with "Division by zero";
                              end if;
                              R := A / B;
                           when others => null;
                        end case;
                        Top := Top + 1;
                        Stack(Top) := R;
                     end;
                  when 'A' .. 'Z' | 'a' .. 'z' =>
                     declare
                        VName : Unbounded_String := Unbounded_Slice(Expr, Start, End_Pos - 1);
                     begin
                        Top := Top + 1;
                        Stack(Top) := Lookup(VName);
                     end;
                  when others =>
                     declare
                        Num : Float := Float'Value(To_String(Unbounded_Slice(Expr, Start, End_Pos - 1)));
                     begin
                        Top := Top + 1;
                        Stack(Top) := Num;
                     end;
               end case;
            end if;
            Start := End_Pos + 1;
         end loop;

         if Top /= 1 then
            raise Program_Error with "Invalid expression";
         end if;
         return Stack(1);
      end Eval_Postfix;

      Temp : Unbounded_String := Null_Unbounded_String;
      Ok : Boolean;
   begin
      Is_OK := True;
      To_Postfix(Expression, Temp, Ok);
      if not Ok then
         Is_OK := False;
         Result := 0.0;
         return;
      end if;
      Result := Eval_Postfix(Temp);
   exception
      when others =>
         Is_OK := False;
         Result := 0.0;
   end Evaluate;

   procedure Calculator is
      Input : Unbounded_String;
      Value : Float;
      OK : Boolean;
   begin
      Put_Line("--- Ada Expression Calculator ---");
      Put_Line("Use 'var x = 5' to assign values");
      Put_Line("Evaluate: (x + 2) * 3 or similar expressions");
      Put_Line("Type 'exit' to close.");

      loop
         Put("=> ");
         Get_Line(Input);
         Input := Sanitize(Input);

         exit when To_Lower(To_String(Input)) = "exit";


         if Length(Input) = 0 then
            null;
         elsif Index(Input, "var ") = 1 then
            declare
               Rest : Unbounded_String := Unbounded_Slice(Input, 5, Length(Input));
               Eq : Natural := Index(Rest, "=");
            begin
               if Eq > 0 then
                  Symbol_Table(Symbol_Count + 1).Name := Sanitize(Unbounded_Slice(Rest, 1, Eq - 1));
                  Symbol_Table(Symbol_Count + 1).Val := Float'Value(To_String(Sanitize(Unbounded_Slice(Rest, Eq + 1, Length(Rest)))));
                  Symbol_Count := Symbol_Count + 1;
                  Put_Line("Variable: " & To_String(Symbol_Table(Symbol_Count).Name) & " = " & Float'Image(Symbol_Table(Symbol_Count).Val));
               else
                  Put_Line("Error: Invalid syntax! Use 'var x = 5'");
               end if;
            end;
         else
            Evaluate(Input, Value, OK);
            if OK then
               Put("Result: ");
               Put(Value, Fore => 1, Aft => 2, Exp => 0);
               New_Line;
            else
               Put_Line("Error: Malformed expression.");
            end if;
         end if;
      end loop;
   end Calculator;

begin
   Calculator;
end Expression_Calculator;
