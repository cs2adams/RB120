class Greeting
  def greet(message)
    puts message
  end

  def self.greet(message)
    puts message
  end
end

class Hello < Greeting
  def hi
    greet("Hello")
  end

  def self.hi
    greet("Hello")
  end
end

class Goodbye < Greeting
  def bye
    greet("Goodbye")
  end
end

Hello.hi