require 'set'
class Trie
  attr_accessor :children, :value

  #def initialize
  #end

  def add(char)
    @children ||= {}
    @children[char] ||= Trie.new
  end

  def child(letter)
    @children[letter] if @children
  end

  def insert(word)
    node = word.chars.inject(self, :add)
    node.value = word
  end

  def find(word)
    node = self
    for char in word.chars
      node = node.child(char) or return
    end
    node.value
  end

  def all_finals
    results = Set.new
    results.add(value) if value
    return results unless @children
    @children.values.map(&:all_finals).inject(results, &:+)
  end

  def autocomplete(prefix)
    node = self
    for char in prefix.chars
      node = node.child(char) or return Set.new
    end
    node.all_finals
  end
end
