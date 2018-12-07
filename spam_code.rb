require 'pry'

# TODO
class String
  def match_interface?
    self =~ /\s*@interface/ and !(self =~ /\/\/\s*@interface/)
  end

  def match_end?
    self =~ /\s*@end/ and !(self =~ /\/\/\s*@end/)
  end

  def match_impl?
    self =~ /\s*@implementation/ and !(self =~ /\/\/\s*@implementation/)
  end
end

class SpamCode
  def initialize(oc_klass_file_name, need_replace = false)
    @han_arr = File.read('han.rb').gsub("\n", "").gsub("\r", "").gsub("\n\r", "").gsub("\"", "").chars
    @han_size = @han_arr.size
    @header_file_name = "#{oc_klass_file_name}.h"
    @impl_file_name   = "#{oc_klass_file_name}.m"
    @need_replace = need_replace
    begin
      @header = File.read(@header_file_name)
    rescue Exception => e
      @header = nil
    end
    begin
      @impl = File.read(@impl_file_name)
    rescue Exception => e
      @impl = nil
    end
  end


  def generate_instance_method(name_length = 5)

    times = rand(7) + rand(3) + 1

    (0..times).collect do |time|
      method_name    = rand_string(name_length)
      parameter_type = rand_type
      parameter_name = rand_string(6)

      if parameter_type == "int"
        head = <<-EOS
          -(void) #{method_name}:(#{parameter_type})#{parameter_name};
        EOS
      else
        head = <<-EOS
          -(void) #{method_name}:(#{parameter_type} *)#{parameter_name};
        EOS
      end

      inbody = case parameter_type
      when "NSString"
        <<-EOS
          if([#{parameter_name} isEqualToString:@"#{rand_string(rand(30))}"]) {
            #{nslog(40)}
          }
        EOS
      when "NSNumber"
        <<-EOS
          if([#{parameter_name} intValue] #{rand_number_options} #{rand_number} ) {
            #{nslog(50)}
          }
        EOS
      when "int"
        <<-EOS
        if(#{parameter_name} #{rand_number_options} #{rand_number(1)}) {
            for (int i = 0; i <= #{rand_number(2)}; i++) {
                #{nslog(30)}
            }
          }
        EOS
      when "BOOL"
        <<-EOS
        if(#{parameter_name}) {
            for (int i = 0; i <= #{rand_number(2)}; i++) {
                #{nslog(30)}
            }
          }
        EOS
      else
        other_name = rand_string(3)
        <<-EOS
        if([#{parameter_name} respondsToSelector:@selector(isEqual:)]) {
            NSNumber *#{other_name} = [NSNumber numberWithInt:#{rand_number(1)}];
            if([#{parameter_name} isEqual:#{other_name}]) {
              #{nslog(50)}
            }
          }
        EOS
      end
      body = <<-EOS
        -(void) #{method_name}:(#{parameter_type}#{parameter_type == 'int' ? '' : " *"})#{parameter_name} {
          #{inbody}
        }
      EOS

      {head: head, impl: body}
    end
  end

  def nslog(length = 50)
    if rand(100) % 2 == 0
      name = rand_string(5)
      <<-EOS
      NSString *#{name} = @"#{rand_output_string(length)}";
      NSLog(@"%@", #{name});
      EOS
    else
      <<-EOS
      NSLog(@"#{rand_output_string(length)}");
      EOS
    end
  end
  
  def rand_type
    index = rand(self.datatypes.size)
    self.datatypes[index]
  end

  def rand_number_options
    arr = [">", "<", "==", ">=", "<=", "!="]
    index = rand(arr.size)
    arr[index]
  end

  def datatypes
    ["NSString", "int", "NSNumber", "NSMutableArray", "BOOL", "NSMutableDictionary"]
  end

  def rand_string(length = 5)
    arr = ('a'..'z').collect{|e| e }
    arr += ('A'..'Z').collect{|e| e }
    (0..(length - 1)).map { arr[rand(arr.length)] }.join
  end

  def rand_han(length = 5)
    return "" if length == 0
    (0..length).collect{|e|
      @han_arr[rand(@han_size)] rescue ''
    }.join
  end

  def rand_output_string(length = 5)
    if rand(100) % 2 == 0
      rand_string(length)
    else
      rand_han(length)
    end
  end

  def rand_number(length = 3)
    n = 1
    return rand(10) if length == 0
    (0..length).each do
      n = n*10
    end
    n + rand(10)
  end

  def doit!
    if @header.nil? or @impl.nil?
      puts @header_file_name
      return
    end

    arr = self.generate_instance_method
    private_arr = self.generate_instance_method
    header_lines = @header.lines
    impl_lines   = @impl.lines
    fake_headers = arr.collect{|e| e[:head] }
    fake_body    = arr.collect{|e| e[:impl] }
    if @need_replace
      h = File.new(@header_file_name, 'wb')
      i = File.new(@impl_file_name, 'wb')
    else
      h = File.new("new_#{@header_file_name}", 'wb')
      i = File.new("new_#{@impl_file_name}", 'wb')
    end

    private_fake_body = private_arr.collect{|e| e[:impl] }

    has_inter = false
    header_lines.each_with_index do |line, index|
      has_interface = false
      h.write(line)
      has_inter = true if line.strip.match_interface?

      next_line = header_lines[index+1].to_s
      if next_line.match_end? and has_inter
        fake_headers.each do |header|
          h.write(header)
        end
      end
    end

    has_impl = false
    has_interface = false
    impl_lines.each_with_index do |line, index|
      has_interface = true if line.match_interface?
      i.write(line)
      next_line = impl_lines[index+1].to_s
      if line.match_impl? and !(next_line =~ /\{/) and !(line =~ /\{/)
        has_impl = true
        has_interface = false
        fake_body.each do |b|
          i.write(b)
        end
      end

      if next_line.match_end? and has_impl  and !has_interface
        private_fake_body.each do |b|
          i.write(b)
        end
      end
    end

    h.close
    i.close
  end

end
