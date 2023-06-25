class Person
  attr_accessor :first_name, :last_name
  
  def initialize(name)
    self.name = name
  end

  def name=(name)
    name = name.split
    self.first_name = name[0]
    last_name = name[1]
    self.last_name = last_name unless last_name.nil?
  end

  def name
    return first_name if last_name.nil?
    first_name + ' ' + last_name
  end

  def to_s
    name
  end
end

bob = Person.new('Robert Smith')
puts "The person's name is: #{bob}"