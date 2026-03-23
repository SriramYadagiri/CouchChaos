const QUESTION_BANK = [
  {
    prompt: "What is the capital of France?",
    difficulty: 1,
    correctColor: "red",
    options: {
      red: "Paris",
      blue: "Berlin",
      yellow: "Madrid",
      green: "Rome"
    }
  },
  {
    prompt: "Which planet is known as the Red Planet?",
    difficulty: 1,
    correctColor: "blue",
    options: {
      red: "Venus",
      blue: "Mars",
      yellow: "Jupiter",
      green: "Saturn"
    }
  },
  {
    prompt: "What does HTML stand for?",
    difficulty: 2,
    correctColor: "yellow",
    options: {
      red: "Hyper Trainer Marking Language",
      blue: "High Text Machine Language",
      yellow: "HyperText Markup Language",
      green: "HyperText Markdown Language"
    }
  },
  {
    prompt: "What is the time complexity of binary search?",
    difficulty: 2,
    correctColor: "green",
    options: {
      red: "O(n)",
      blue: "O(n^2)",
      yellow: "O(1)",
      green: "O(log n)"
    }
  },
  {
    prompt: "What programming language is primarily used for Roku channel development?",
    difficulty: 1,
    correctColor: "blue",
    options: {
      red: "JavaScript",
      blue: "BrightScript",
      yellow: "Python",
      green: "C++"
    }
  },
  {
    prompt: "In BrightScript, which keyword is used to define a function?",
    difficulty: 2,
    correctColor: "yellow",
    options: {
      red: "func",
      blue: "def",
      yellow: "function",
      green: "sub"
    }
  },
  {
    prompt: "What type of data structure is an associative array in BrightScript?",
    difficulty: 3,
    correctColor: "green",
    options: {
      red: "List",
      blue: "Stack",
      yellow: "Queue",
      green: "Dictionary (key-value pairs)"
    }
  },
  {
    prompt: "What does 'SceneGraph' refer to in Roku development?",
    difficulty: 3,
    correctColor: "red",
    options: {
      red: "A UI framework for building Roku interfaces",
      blue: "A graphics card feature",
      yellow: "A video codec",
      green: "A networking protocol"
    }
  },
  {
    prompt: "Which method is commonly used to print debug messages in BrightScript?",
    difficulty: 2,
    correctColor: "blue",
    options: {
      red: "console.log()",
      blue: "print",
      yellow: "echo()",
      green: "debug()"
    }
  },
  {
    prompt: "How many sides does a hexagon have?",
    difficulty: 1,
    correctColor: "yellow",
    options: {
      red: "5",
      blue: "7",
      yellow: "6",
      green: "8"
    }
  },
  {
    prompt: "What year did the first iPhone launch?",
    difficulty: 1,
    correctColor: "red",
    options: {
      red: "2007",
      blue: "2005",
      yellow: "2009",
      green: "2010"
    }
  },
  {
    prompt: "Which ocean is the largest?",
    difficulty: 1,
    correctColor: "green",
    options: {
      red: "Atlantic",
      blue: "Indian",
      yellow: "Arctic",
      green: "Pacific"
    }
  },
  {
    prompt: "What is the chemical symbol for gold?",
    difficulty: 2,
    correctColor: "red",
    options: {
      red: "Au",
      blue: "Ag",
      yellow: "Go",
      green: "Gd"
    }
  },
  {
    prompt: "Which data structure operates on a LIFO basis?",
    difficulty: 2,
    correctColor: "blue",
    options: {
      red: "Queue",
      blue: "Stack",
      yellow: "Heap",
      green: "Graph"
    }
  },
  {
    prompt: "What does CSS stand for?",
    difficulty: 1,
    correctColor: "green",
    options: {
      red: "Computer Style Sheets",
      blue: "Creative Style System",
      yellow: "Colorful Styling Script",
      green: "Cascading Style Sheets"
    }
  },
  {
    prompt: "Which sorting algorithm has an average time complexity of O(n log n)?",
    difficulty: 3,
    correctColor: "yellow",
    options: {
      red: "Bubble Sort",
      blue: "Insertion Sort",
      yellow: "Merge Sort",
      green: "Selection Sort"
    }
  },
  {
    prompt: "What does API stand for?",
    difficulty: 2,
    correctColor: "red",
    options: {
      red: "Application Programming Interface",
      blue: "Automated Processing Input",
      yellow: "Applied Protocol Integration",
      green: "Active Program Interchange"
    }
  },
  {
    prompt: "In JavaScript, which keyword declares a block-scoped variable?",
    difficulty: 2,
    correctColor: "blue",
    options: {
      red: "var",
      blue: "let",
      yellow: "define",
      green: "set"
    }
  },
  {
    prompt: "What is the maximum number of children a binary tree node can have?",
    difficulty: 2,
    correctColor: "green",
    options: {
      red: "1",
      blue: "3",
      yellow: "4",
      green: "2"
    }
  },
  {
    prompt: "Which HTTP status code indicates a resource was not found?",
    difficulty: 2,
    correctColor: "yellow",
    options: {
      red: "200",
      blue: "500",
      yellow: "404",
      green: "301"
    }
  },
  {
    prompt: "What is a closure in programming?",
    difficulty: 3,
    correctColor: "red",
    options: {
      red: "A function that retains access to its outer scope",
      blue: "A method that closes a database connection",
      yellow: "A type of loop that terminates early",
      green: "A sealed class that cannot be extended"
    }
  },
  {
    prompt: "Which protocol is used to send email?",
    difficulty: 2,
    correctColor: "blue",
    options: {
      red: "FTP",
      blue: "SMTP",
      yellow: "HTTP",
      green: "SSH"
    }
  },
  {
    prompt: "What does the 'V' stand for in MVC architecture?",
    difficulty: 2,
    correctColor: "green",
    options: {
      red: "Variable",
      blue: "Version",
      yellow: "Validator",
      green: "View"
    }
  },
  {
    prompt: "Which number system uses a base of 16?",
    difficulty: 3,
    correctColor: "yellow",
    options: {
      red: "Binary",
      blue: "Octal",
      yellow: "Hexadecimal",
      green: "Decimal"
    }
  },
  {
    prompt: "What is a race condition in software?",
    difficulty: 3,
    correctColor: "red",
    options: {
      red: "When two processes compete to access shared data unpredictably",
      blue: "When a program runs faster than expected",
      yellow: "A benchmark test comparing CPU speeds",
      green: "A scheduling algorithm for threads"
    }
  }
];
 
module.exports = QUESTION_BANK;