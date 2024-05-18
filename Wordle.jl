### A Pluto.jl notebook ###
# v0.19.38

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ ff5f621c-8c9f-48d9-a184-57fefaa4fe9b
begin
    import Pkg
	io = IOBuffer()
    Pkg.activate(io = io)
	deps = [pair.second for pair in Pkg.dependencies()]
	direct_deps = filter(p -> p.is_direct_dep, deps)
    pkgs = [x.name for x in direct_deps]
	if "PlutoUI" ∉ pkgs
		Pkg.add(url="https://github.com/JuliaPluto/PlutoUI.jl")
	end

	using PlutoUI
end

# ╔═╡ c8d48230-1464-11ef-0630-b98de5d1ae8d
md"""
# Little project: A Wordle Solver
There are 8258 words of 5 letters in the English dictionary (at least on the file that I received during a course at the university) but only 2315 are allowed in the original version of the game.\
I found all the words I use here on the website of the _Departement of Mathematics_ of _The University of Texas at Austin_ (https://web.ma.utexas.edu/users/rusin/wordle/official).
"""

# ╔═╡ 80ac0014-8a0b-4246-a561-e623f4808e66
md"""
I have added a **file called 'Wordle.txt'** on my GitHub, please **save it in the same folder as this notebook.**
"""

# ╔═╡ 0c85d433-5692-410c-b3e6-b825ea721fc7
# https://github.com/aurelienhbts/PlutoWordle

# ╔═╡ db716fdd-33f3-4575-9f6f-1abfc651db15
mutable struct Wordle
	word :: String # The secret word 
	guess :: String # The current guess
	guesses :: Array # ALl the guesses
	correct :: Array # The correct letters (at the right place)
	inword :: Array  # The letters in the word but not at the right place
	notin :: Array # The letters that aren't in the word
	posnot :: Dict
	graphics :: Array # To store all the lines of emoji's
end

# ╔═╡ dcc7bbea-407b-4824-bf35-eaebc1a6ddb8
function start_posnot()
	d = Dict()

	alphabet = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']

	for idx in 1:26
		letter = alphabet[idx]
		d[letter] = []
	end
	return d
end

# ╔═╡ 6cb7b734-508c-46a8-b014-68ba8069282e
function reset_w()
	return Wordle("", "", String[], Tuple[], Char[], Char[], start_posnot(), [String[], String[], String[], String[], String[], String[]])
end

# ╔═╡ 354bf5cb-7f4d-4a60-a69e-3f22b44e03d0
# This function is a modified version of the 'histogram' function.
# From the 11th lecture of ES123 (Computer Algorithms and Programming Project).

function count(word, char)
	
	d = Dict()
	
	for c in word
		if c ∉ keys(d)
			d[c] = 1
		else
			d[c] += 1
		end
	end

	n = get(d, char, 0)
	
	return n
end

# ╔═╡ 442b85d5-2f8c-4549-a3c1-1d8e1fd7e458
md"""
## With some graphics
Here is a simple version of the game (made using emoji's)
"""

# ╔═╡ 9d1dabc1-3c3d-4edf-9519-e0b643445fb1
md"""Click here to start the game: $(@bind start Button("Start Game"))"""

# ╔═╡ e0cf84bf-15b0-4bdb-86a4-a9076237e552
begin
	start
	w = reset_w()

	md"""Here is the code that runs when pressing "Start Game" button:"""
end

# ╔═╡ 2d8cfc6f-ab0b-4bfc-aa4e-5bf14b2003a7
function secret_word()
	
	idx = rand(1:2315)
	path = joinpath(splitdir(@__FILE__)[1], "Wordle.txt")

	k = 0
	
	for line in eachline(joinpath(path))
		k += 1
		if k == idx
			w.word = line
			break
		end
	end 
end

# ╔═╡ 32c339e9-4976-4e6f-8e3a-514883f3d308
secret_word()

# ╔═╡ fdf7557e-37cb-44c1-8546-c518592279bb
function compare_words(guess)

	path = joinpath(splitdir(@__FILE__)[1], "Wordle.txt")
	test = 0
	for line in eachline(joinpath(path))
		if line == guess # Verify if the provided word exist in the list
			test += 1
		end
	end

	if test == 0
		error("The choosen word is not in the list.")
	else

		w.guess = guess # Set the current guess in the mutable structure
	
		if guess ∉ w.guesses
			push!(w.guesses, guess)
		end
		
		secretchars = collect(w.word)
		guesschars = collect(guess)
	
		output = [0, 0, 0, 0, 0]
		preoutput = []
		
		for i in 1:5
			char = guesschars[i]
			
			if char ∉ w.word
				output[i] = 0 # 0 if the letter is not in the word
				
				if char ∉ w.notin
					push!(w.notin, char)
				end
				
			elseif secretchars[i] == char
				output[i] = 1 # 1 if the letter is at the correct place
				
				if (i, char) ∉ w.correct
					push!(w.correct, (i, char))
					n = count(w.word, char)
					test = 0
					for correct in w.correct
						if correct[2] == char
							test += 1
						end
					end
					if n == test # If all the 'i' have been found, remove 'char'
						filter!(x -> x != char, w.inword)
					end
				end
				
			elseif secretchars[i] != char && char ∈ w.word
				push!(preoutput, (i, char))
					
				n = count(w.word, char)
				test = 0
				for correct in w.correct
					if correct[2] == char
						test += 1
					end
				end
				if n > 1 && n == test
					output[i] = 0
				end
				
				if char ∉ w.inword
					push!(w.inword, char)
				end
				
				d = w.posnot
				if i ∉ values(d[char])
					push!(values(d[char]), i) # Add the index in w.posnot('char')
				end
			end
		end

        function process_preoutput(preoutput, output, secretchars)
            if length(preoutput) == 1
                (i, char) = preoutput[1]
                output[i] = 2
            elseif length(preoutput) == 2
                (i1, char1) = preoutput[1]
                (i2, char2) = preoutput[2]
                if char1 == char2
                    n = count(secretchars, char1)
                    if n == 2
                        output[i1] = 2
                        output[i2] = 1
                    else
                        output[i1] = 2
                        output[i2] = 2
                    end
                else
                    output[i1] = 2
                    output[i2] = 2
                end
            elseif length(preoutput) == 3
                (i1, char1) = preoutput[1]
                (i2, char2) = preoutput[2]
                (i3, char3) = preoutput[3]
                if char1 == char2 && char2 == char3
                    n = count(secretchars, char1)
                    if n == 3
                        output[i1] = 2
                        output[i2] = 2
                        output[i3] = 1
                    else
                        output[i1] = 2
                        output[i2] = 2
                        output[i3] = 2
                    end
                elseif char1 == char2
                    n = count(secretchars, char1)
                    if n == 2
                        output[i1] = 2
                        output[i2] = 2
                        output[i3] = 0
                    else
                        output[i1] = 2
                        output[i2] = 2
                        output[i3] = 2
                    end
                elseif char2 == char3
                    n = count(secretchars, char2)
                    if n == 2
                        output[i1] = 0
                        output[i2] = 2
                        output[i3] = 2
                    else
                        output[i1] = 2
                        output[i2] = 2
                        output[i3] = 2
                    end
                elseif char1 == char3
                    n = count(secretchars, char1)
                    if n == 2
                        output[i1] = 2
                        output[i2] = 0
                        output[i3] = 2
                    else
                        output[i1] = 2
                        output[i2] = 2
                        output[i3] = 2
                    end
                else
                    output[i1] = 2
                    output[i2] = 2
                    output[i3] = 2
                end
            elseif length(preoutput) == 4
                (i1, char1) = preoutput[1]
                (i2, char2) = preoutput[2]
                (i3, char3) = preoutput[3]
                (i4, char4) = preoutput[4]
                chars = [char1, char2, char3, char4]
                unique_chars = unique(chars)
                for char in unique_chars
                    indices = findall(x -> x == char, chars)
                    n = count(secretchars, char)
                    if length(indices) <= n
                        for idx in indices
                            output[preoutput[idx][1]] = 2
                        end
                    else
                        for idx in indices
                            output[preoutput[idx][1]] = 1
                        end
                    end
                end
            elseif length(preoutput) == 5
                (i1, char1) = preoutput[1]
                (i2, char2) = preoutput[2]
                (i3, char3) = preoutput[3]
                (i4, char4) = preoutput[4]
                (i5, char5) = preoutput[5]
                chars = [char1, char2, char3, char4, char5]
                unique_chars = unique(chars)
                for char in unique_chars
                    indices = findall(x -> x == char, chars)
                    n = count(secretchars, char)
                    if length(indices) <= n
                        for idx in indices
                            output[preoutput[idx][1]] = 2
                        end
                    else
                        for idx in indices
                            output[preoutput[idx][1]] = 1
                        end
                    end
                end
            end
        end

        process_preoutput(preoutput, output, secretchars)
        
        return output
    end
end

# ╔═╡ 28994152-5971-4cbf-b298-5f3fe7cc0336
function play(word)
	
	result = compare_words(word)
    
    output = String[]
    
    for k in 1:5
        if result[k] == 0
            push!(output, "$(word[k]) 🔳")
        elseif result[k] == 1
            push!(output, "$(word[k]) 🟩")
        elseif result[k] == 2
            push!(output, "$(word[k]) 🟨")
        end
    end
	
	g = w.graphics 
	l = length(w.guesses)
	if l < 7
		g[l] = output
	else
		println("You lost, the word was $(w.word)")
		println(" ")
	end

	for guess in g
		if length(guess) > 0
			println(guess)
		end
	end
end

# ╔═╡ d0de1a34-eeed-4817-8aa3-81d1e57b656e
function solver()

	correct = w.correct
	inword = w.inword
	notin = w.notin

	path = joinpath(splitdir(@__FILE__)[1], "Wordle.txt")
	    
    output = []
	    
	for line in eachline(path)
			
	    valid = true
		ok = true
	    
        for (pos, char) in correct
	        if line[pos] != char
	            valid = false
	            break
	        end
	    end
	        
	    for char in inword
	        if char ∉ line
                valid = false
	            break
	        end
	    end
	        
	    for char in notin
	        if char ∈ line
	            valid = false
	            break
	        end
	    end
		
	    if valid
			d = w.posnot
			chars = collect(line)
			for key in keys(d)
				for pos in 1:5
					if chars[pos] == key
						if pos ∈ d[key]
							ok = false
						end
					end
				end
			end
	    end

		if ok && valid
			push!(output, line)
		end
		
	end
	
    return output
end

# ╔═╡ a7219f5a-f24e-483b-800f-60cfb4a7307d
function run_solver()

	word = "crane"
	@show word
	
	while true
		
		r = compare_words(word)
		
        if r == [1, 1, 1, 1, 1]
			println("found")
			break
		else
			println("not yet")
			possibilities = solver()
            idx = rand(1:length(possibilities))
            word = possibilities[idx]
			@show word
		end
    end
end

# ╔═╡ 0b275ad6-74ff-4189-9b7c-37cc51f6d118
md"""
Put your guess here: 
$(@bind word confirm(TextField(default="crane")))
"""

# I have set "crane" by default because it is the word that will have a greater probability to give a lot of informations.

# ╔═╡ d204f0f2-55a3-4076-961a-4075cde5c52d
begin
	play(word)
end

# ╔═╡ 0b983516-022a-4772-965f-4b702f2ee8d2
solver() # To get the possibilities

# ╔═╡ 63bd33e1-5cf2-4786-8bf2-2247ed648e53
#run_solver()

# ╔═╡ Cell order:
# ╟─ff5f621c-8c9f-48d9-a184-57fefaa4fe9b
# ╟─c8d48230-1464-11ef-0630-b98de5d1ae8d
# ╟─80ac0014-8a0b-4246-a561-e623f4808e66
# ╠═0c85d433-5692-410c-b3e6-b825ea721fc7
# ╠═db716fdd-33f3-4575-9f6f-1abfc651db15
# ╟─dcc7bbea-407b-4824-bf35-eaebc1a6ddb8
# ╟─6cb7b734-508c-46a8-b014-68ba8069282e
# ╟─2d8cfc6f-ab0b-4bfc-aa4e-5bf14b2003a7
# ╟─354bf5cb-7f4d-4a60-a69e-3f22b44e03d0
# ╟─fdf7557e-37cb-44c1-8546-c518592279bb
# ╟─28994152-5971-4cbf-b298-5f3fe7cc0336
# ╟─d0de1a34-eeed-4817-8aa3-81d1e57b656e
# ╟─a7219f5a-f24e-483b-800f-60cfb4a7307d
# ╟─e0cf84bf-15b0-4bdb-86a4-a9076237e552
# ╟─32c339e9-4976-4e6f-8e3a-514883f3d308
# ╟─442b85d5-2f8c-4549-a3c1-1d8e1fd7e458
# ╟─9d1dabc1-3c3d-4edf-9519-e0b643445fb1
# ╟─0b275ad6-74ff-4189-9b7c-37cc51f6d118
# ╠═d204f0f2-55a3-4076-961a-4075cde5c52d
# ╠═0b983516-022a-4772-965f-4b702f2ee8d2
# ╠═63bd33e1-5cf2-4786-8bf2-2247ed648e53
