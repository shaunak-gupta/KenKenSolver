require 'enumerator'
require 'prime'

class KenkenSolver
	def initialize
		@grid = Grid.new
	end
	
	def solve_puzzle
		block, cell_index = @grid.next_cell
		until cell_index.nil?
			taboo_numbers = @grid.taboo_numbers(cell_index)
			block_values = block.values
			cell = block.get_cell_by_index(cell_index)
			case block.operator
				when (' ' or '')
					new_cell_value = cell.probable_value(block.value, block.operator, block.size, @grid.size, taboo_numbers)
				when '+'
					block_value = block.value
					block_values.each do |existing_num|
						block_value = block_value - existing_num
					end
					if block.size - block_values.count == 1
						operator = ' '
					else
						operator = '+'
					end
					new_cell_value = cell.probable_value(block_value, operator, block.size - block_values.count, @grid.size, taboo_numbers)
				when '-'
					block_value = block.value
					if block_values.count > 0
						if block_value + block_values[0] <= @grid.size and !taboo_numbers.include?(block_value + block_values[0]) and !cell.history.include?(block_value + block_values[0])
							new_cell_value = block_value + block_values[0]
						elsif block_values[0] - block.value > 0 and !taboo_numbers.include?(block_values[0] - block.value) and !cell.history.include?(block_values[0] - block.value)
							new_cell_value = block_values[0] - block.value
						else
							new_cell_value = nil
						end
					else
						new_cell_value = cell.probable_value(block_value, block.operator, block.size - block_values.count, @grid.size, taboo_numbers)
					end
				when '%'
					block_value = block.value
					if block_values.count > 0
						if block_value * block_values[0] <= @grid.size and !taboo_numbers.include?(block_value * block_values[0]) and !cell.history.include?(block_value * block_values[0])
							new_cell_value = block_value * block_values[0]
						elsif block_values[0] % block.value == 0 and !taboo_numbers.include?(block_values[0]/block.value) and !cell.history.include?(block_values[0]/block.value)
							new_cell_value = block_values[0] / block.value
						else
							new_cell_value = nil
						end
					else
						new_cell_value = cell.probable_value(block_value, block.operator, block.size - block_values.count, @grid.size, taboo_numbers)
					end
				when '*'
					block_value = block.value
					block_values.each do |existing_num|
						block_value = block_value / existing_num
					end
					if block.size - block_values.count == 1
						operator = ' '
					else
						operator = '*'
					end
					new_cell_value = cell.probable_value(block_value, operator, block.size - block_values.count, @grid.size, taboo_numbers)
			end
			cell.update_value(new_cell_value)
			@grid.update_table(new_cell_value,cell_index)
			if new_cell_value.nil?
				block, cell_index = @grid.previous_cell
			else
				block, cell_index = @grid.next_cell
			end
		end
		table = @grid.display
		puts table
		return table
	end
		
	attr_reader :grid
	
	class Grid
		attr_reader :size, :table
		def initialize
			@size = 0
			@stack = Array.new
			@blocks = Hash.new
			@index_map = Hash.new
		end
		def load_data(file_path)
			File.open(file_path) do |file|
				cell_index = 0
				until file.eof?
				  row = file.readline.chomp.split(',')
				  if @size == 0
				  	@size = row.count / 3
				  	@table = Array.new(@size) {Array.new(@size)} 
				  end
				  row.each_slice(3) do |cell|
				  	cell[0] = cell[0].to_i
				  	cell[1] = cell[1].to_i
				  	if cell[2].nil? or cell[2] == ''
				  		cell[2] = ' '
				  	end
				  	if @blocks.has_key?cell[0]
				  		@blocks[cell[0]].add_cell(cell, cell_index)
				  	else
				  		@blocks[cell[0]] = Block.new(cell, cell_index, cell[0])
				  	end
				  	@index_map[cell_index] = cell[0]
				  	cell_index += 1
				  end
				end
	  		end
		end
		def next_cell
			if @table.flatten.index(nil) == nil
				return nil,nil
			end
			block_list = @blocks.select {|key,value| value.available_cells.count > 0}
			block = block_list.values.sort.first
			cell_index = Hash[block.available_cells.keys.map {|index| [index, taboo_numbers(index).count]}].max_by {|index, taboo_count| taboo_count}[0]
			@stack.push(cell_index)
			return block, cell_index
		end
		def previous_cell
			current_index = @stack.pop
			current_block_id = @index_map[current_index]
			current_block = @blocks[current_block_id]
			current_cell = current_block.get_cell_by_index(current_index)
			current_cell.history = []
			prev_index = @stack[-1]
			if prev_index == nil
				return nil, nil
			end
			prev_block_id = @index_map[prev_index]
			prev_block = @blocks[prev_block_id]
			prev_cell = prev_block.get_cell_by_index(prev_index)
			prev_cell.value = nil 
			update_table(nil, prev_index)
			return prev_block, prev_index
		end
		def taboo_numbers(cell_index)
			taboo = @table[cell_index/@size] + @table.map {|row| row[cell_index%@size]}
			taboo.delete(nil)
			return taboo.uniq
		end
		
		def update_table(new_cell_value,cell_index)
			@table[cell_index/@size][cell_index%@size] = new_cell_value
		end
		def cell_value(cell_index)
			@table[cell_index/@size][cell_index%@size]
		end
		def display
			table = ""
			@table.each do |row|
				table = table + row.join(',') + "\n"
			end
			return table
		end

		
		class Block
			attr_reader :operator, :value, :id
			def initialize(cell, cell_index, block_id)
				@cells = Hash.new
				@cells[cell_index] = Cell.new(cell_index)
				@value = cell[1]
				@operator = cell[2]
				@id = block_id
			end
			def add_cell(cell, cell_index)
				@cells[cell_index] = Cell.new(cell_index)
			end
			
			def values
				values = Array.new
				@cells.each do |index, cell|
					if !cell.value.nil?
						values.push(cell.value)
					end
				end
				return values
			end
			
			def size
				@cells.count
			end
			
			def <=>(block2)
				self_available_cells_count = self.available_cells.count
				block2_available_cells_count = block2.available_cells.count
				if self_available_cells_count < block2_available_cells_count
					return -1
				elsif self_available_cells_count > block2_available_cells_count
					return 1
				else
					oper_list = [' ','','%','-','*','+']
					if oper_list.index(self.operator) < oper_list.index(block2.operator)
						return -1
					elsif oper_list.index(self.operator) > oper_list.index(block2.operator)
						return 1
					else
						return 0
					end
				end
			end
			def get_cell_by_index(cell_index)
				@cells[cell_index]
			end
			
			def available_cells
				return @cells.select {|index, cell| cell.value == nil}
			end
			
			class Cell
				attr_reader :index
				attr_accessor :value, :history
				def initialize(cell_index)
					@value = nil
					@history = Array.new
					@index = cell_index
				end
				def update_value(value)
					@value = value
					if !value.nil?
						@history.push(value)
					end
				end
				def probable_value(clue, operator, size, max, taboo)
					probabilities = Hash.new
					case operator.strip
						when ('' or ' ')							#No operator means a one-sized block, answer=clue unless it is @taboo
							(1..max).each do |index|
								probabilities[index] = 0
							end
							if !taboo.include?clue and !@history.include?clue
								probabilities[clue] = 1
							end				
						when '+'
							(1..max).each do |index|
								if taboo.include?index or @history.include?index or (clue - index) < (size - 1) or (clue - index)/(size - 1) > max
									probabilities[index] = 0
								elsif index == max-2 and size == 2 and clue == 2*max - 2
									probabilities[index] = 0.5
								elsif index == max-1 and size == 2 and clue == 2*max - 1
									probabilities[index] = 0.5
								elsif index >= max-2 and size == 3 and clue == 3*max - 3
									probabilities[index] = 0.33
								else
									probabilities[index] = 1.0/(clue*clue+1)
								end
							end

						when '-'						#Only 2 elements in a block with minus operator
							possibilities = 2*(max - clue)
							blacklist = (taboo + @history).uniq
							blacklist.each do |num|
								if num <= max-clue and num > clue
									possibilities= possibilities-2
								elsif num <= max-clue or num > clue
									possibilities= possibilities-1
								end
							end
					
							(1..max).each do |index|
								if taboo.include?index or @history.include?index
									probabilities[index] = 0
								elsif index <= max-clue and index > clue
									probabilities[index] = 2.0/possibilities
								elsif index <= max-clue or index > clue
									probabilities[index] = 1.0/possibilities
								else
									probabilities[index] = 0
								end
							end
				  		when '%'						#Only 2 elements in a block with divide operator
				  			possibilities = 2*(max / clue)
				  			blacklist = (taboo + @history).uniq
				  			blacklist.each do |num|
								if num*clue <= max and num >= clue and num % clue == 0
									possibilities= possibilities-2
								elsif num*clue <= max or (num >= clue and num % clue == 0)
									possibilities= possibilities-1
								end
							end
							(1..max).each do |index|
								if taboo.include?index or @history.include?index
									probabilities[index] = 0
								elsif index*clue <= max and index >= clue and index % clue == 0
									probabilities[index] = 2.0/possibilities
								elsif index <= max/clue or (index >= clue and index % clue == 0)
									probabilities[index] = 1.0/possibilities
								else
									probabilities[index] = 0
								end
							end
				  		when '*'
				  			factor_list = Hash[clue.prime_division.map {|factor| factor}]
				  			factor_list[1] = 1
				  			factor_count = factor_list.values.inject(:+)
							(1..max).each do |index|
								if taboo.include?index or @history.include?index or clue % index != 0
									probabilities[index] = 0
								elsif clue == index
									probabilities[index] = 0.5
								elsif size == 2 and clue % index == 0 and clue/index <= max
									probabilities[index] = 0.5
								elsif size == 2 and clue % index == 0 and clue/index > max
									probabilities[index] = 0
								elsif size == 2 and clue == max*(max-1) and (index > max-2)
									probabilities[index] = 0.5
								elsif size == 3 and clue == max*(max-1)*(max-2) and (index > max-3)
									probabilities[index] = 0.33
								elsif index == 1 and (factor_list[2].to_i + factor_list[3].to_i > 4 or size > factor_count)
									probabilities[index] = (0.5 + factor_list[2].to_i/3 + factor_list[3].to_i/2) * 1.0/factor_count
								elsif index == 4
									probabilities[index] = factor_list[2].to_i/2 * 1.0/factor_count
								elsif index == 8
									probabilities[index] = factor_list[2].to_i/3 *1.0/factor_count
								elsif index == 9
									probabilities[index] = factor_list[3].to_i/2 *1.0/factor_count
								elsif index == 6
									probabilities[index] = (factor_list[2].to_i < factor_list[3].to_i ? factor_list[2].to_i : factor_list[3].to_i) * 1.0/(factor_count)
								else
									probabilities[index] = factor_list[index].to_i* 1.0/(factor_count)
								end
							end			
					end
					if probabilities.values.max > 0
						return probabilities.key(probabilities.values.max)
					else
						return nil
					end
				end
			end
		end
	end
end
files = Dir["input/*"]
files = files.sort_by {|file_path| File.size(file_path)}
files.each do |file_path|
	puzzle = KenkenSolver.new
	beginning = Time.now
	puzzle.grid.load_data(file_path)
	grid = puzzle.solve_puzzle
	output_name = file_path.sub /input/i, 'results'
	File.open(output_name, 'w') do |file| 
		file.write(grid.to_s)
	end
	puts "Time taken = " + (Time.now - beginning).to_s
end
