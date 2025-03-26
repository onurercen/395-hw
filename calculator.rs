use std::collections::HashMap;
use std::io::{self, Write};

fn tokenize(input: &str) -> Vec<String> {
    let mut tokens = Vec::new();
    let mut current = String::new();
    
    for c in input.chars() {
        if c.is_whitespace() {
            continue;
        } else if "+-*/=()".contains(c) {
            if !current.is_empty() {
                tokens.push(current.clone());
                current.clear();
            }
            tokens.push(c.to_string());
        } else {
            current.push(c);
        }
    }
    
    if !current.is_empty() {
        tokens.push(current);
    }
    
    tokens
}

fn parse_expr(tokens: &[String], vars: &mut HashMap<String, f64>) -> Result<f64, String> {
    if tokens.len() > 2 && tokens[1] == "=" {
        let var_name = &tokens[0];
        let expr_value = eval_expr(&tokens[2..], vars)?;
        vars.insert(var_name.clone(), expr_value);
        return Ok(expr_value);
    }
    eval_expr(tokens, vars)
}

fn eval_expr(tokens: &[String], vars: &mut HashMap<String, f64>) -> Result<f64, String> {
    let mut stack: Vec<f64> = Vec::new();
    let mut ops: Vec<String> = Vec::new();
    let mut index = 0;

    while index < tokens.len() {
        let token = &tokens[index];

        if let Ok(num) = token.parse::<f64>() {
            stack.push(num);
        } else if let Some(&val) = vars.get(token) {
            stack.push(val);
        } else if token == "(" {
            ops.push(token.clone());
        } else if token == ")" {
            while let Some(op) = ops.pop() {
                if op == "(" {
                    break;
                }
                apply_operator(&mut stack, &op)?;
            }
        } else if "+-*/".contains(token) {
            while let Some(last_op) = ops.last() {
                if precedence(last_op) >= precedence(token) {
                    apply_operator(&mut stack, ops.pop().unwrap().as_str())?;
                } else {
                    break;
                }
            }
            ops.push(token.clone());
        } else {
            return Err("Invalid token".to_string());
        }
        index += 1;
    }

    while let Some(op) = ops.pop() {
        apply_operator(&mut stack, &op)?;
    }

    stack.pop().ok_or("Invalid expression".to_string())
}

fn precedence(op: &str) -> i32 {
    match op {
        "+" | "-" => 1,
        "*" | "/" => 2,
        _ => 0,
    }
}

fn apply_operator(stack: &mut Vec<f64>, op: &str) -> Result<(), String> {
    if stack.len() < 2 {
        return Err("Invalid expression".to_string());
    }
    let b = stack.pop().unwrap();
    let a = stack.pop().unwrap();
    stack.push(match op {
        "+" => a + b,
        "-" => a - b,
        "*" => a * b,
        "/" => {
            if b == 0.0 {
                return Err("Division by zero".to_string());
            }
            a / b
        }
        _ => return Err("Unknown operator".to_string()),
    });
    Ok(())
}

fn main() {
    let mut vars: HashMap<String, f64> = HashMap::new();
    let stdin = io::stdin();

    loop {
        print!("calc> ");
        io::stdout().flush().unwrap();
        
        let mut input = String::new();
        if stdin.read_line(&mut input).is_err() {
            println!("Error reading input");
            continue;
        }
        
        let input = input.trim();
        if input == "exit" { break; }
        
        let tokens = tokenize(input);
        match parse_expr(&tokens, &mut vars) {
            Ok(value) => println!("{}", value),
            Err(e) => println!("Error: {}", e),
        }
    }
}
