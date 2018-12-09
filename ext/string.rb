
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