#!/usr/bin/env ruby
# based on python program By Steve Hanov, 2011. Released to the public domain.

DICTIONARY = "/usr/share/dict/words"
DUMP = './hashwords.dump'

# This class represents a node in the directed acyclic word graph (DAWG). It
# has a list of edges to other nodes. It has functions for testing whether it
# is equivalent to another node. Nodes are equivalent if they have identical
# edges, and each identical edge leads to identical states. The __hash__ and
# __eq__ functions allow it to be used as a key in a python dictionary.
class DawgNode < Hash

  attr_accessor :final

  # def hash наследуем

  def eql?(other)
    super && @final == other.final
  end

  def all_finals(prefix='')
    results = []
    results << prefix if @final
    # return results unless @edges
    each do |letter, node|
      results += node.all_finals(prefix + letter.to_s)
    end
    results
  end


end

class Dawg
  def initialize
    @previous_word = ""
    @root = DawgNode.new

    # Here is a list of nodes that have not been checked for duplication.
    @unchecked_nodes = []

    # Here is a list of unique nodes that have been checked for
    # duplication.
    @minimized_nodes = {}
  end

  def load(filename)
    @root = Marshal.load(File.read(filename))
  end

  def save(filename)
    File.open(filename, 'w') {|f| Marshal.dump(@root, f) }
  end

  def insert( word )
    if word < @previous_word
      raise "Words must be inserted in alphabetical order."
    end

    # find common prefix between word and previous word
    common_prefix = 0
    word.size.times do |i|
      break if word[i] != @previous_word[i]
      common_prefix += 1
    end

    # Check the uncheckedNodes for redundant nodes, proceeding from last
    # one down to the common prefix size. Then truncate the list at that
    # point.
    minimize( common_prefix )

    # add the suffix, starting from the correct node mid-way through the
    # graph
    if @unchecked_nodes.empty?
      node = @root
    else
      node = @unchecked_nodes.last[2]
    end

    for letter in word[common_prefix..-1].chars
      next_node = DawgNode.new
      node[letter.to_sym] = next_node
      @unchecked_nodes << [node, letter.to_sym, next_node]
      node = next_node
    end

    node.final = true
    @previous_word = word
  end

  def finish
    # minimize all uncheckedNodes
    minimize( 0 )
  end

  def minimize( down_to )
    # proceed from the leaf up to a certain point
    while @unchecked_nodes.size > down_to
      parent, letter, child = @unchecked_nodes.pop
      # минимизированные ноды содержат *эквивалент* текущей ноды?
      if @minimized_nodes.include?(child)
        # replace the child with the previously encountered one
        parent[letter] = @minimized_nodes[child]
      else
        # add the state to the minimized nodes.
        @minimized_nodes[child] = child
      end
    end
  end

  def lookup( word )
    node = @root
    for letter in word.chars
      node = node[letter.to_sym] or return
    end
    node.final
  end

  def autocomplete(prefix)
    node = @root
    for letter in prefix.chars
      node = node[letter.to_sym] or return []
    end
    node.all_finals(prefix)
  end

  def node_count
    @minimized_nodes.size
  end

  def edge_count
    @minimized_nodes.keys.collect {|node| node.size}.inject(0, :+)
  end

end


dawg = Dawg.new
if File.exists? DUMP
  start = Time.now
  dawg.load(DUMP)
  puts "Dawg loading took %g s" % (Time.now-start)
  ObjectSpace.garbage_collect
  puts ObjectSpace.count_objects
else
  words = File.read(DICTIONARY).split.sort
  word_count = 0

  start = Time.now
  for word in words
    word_count += 1
    dawg.insert(word)
    if word_count.modulo(100).zero?
      print "%d\r" % word_count
    end
  end
  dawg.finish
  puts "Dawg creation took %g s" % (Time.now-start)

  edge_count = dawg.edge_count
  puts "Read %d words into %d nodes and %d edges" % [ word_count, dawg.node_count, dawg.edge_count ]
  puts "This could be stored in as little as %d bytes" % [edge_count * 4]
  dawg.save(DUMP)
end


for word in ARGV
  puts " #{word} =>"
  puts dawg.autocomplete(word)
end
__END__
for word in ARGV
  if dawg.lookup( word )
    puts "#{word} is in the dictionary."
  else
    puts "#{word} not in dictionary."
  end
end
