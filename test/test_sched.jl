push!(LOAD_PATH, "./src")

using SimpleAgentEvents
using SimpleAgentEvents.Scheduler


mutable struct Model
end

struct Simulation
	scheduler :: PQScheduler{Float64}
	model :: Model
end

scheduler(sim) = sim.scheduler


mutable struct A1
	id :: Int
	state :: Int
	food :: Int
end


function A1(i)
	A1(i, 0, 0)
end


function wakeup(a::A1, model)
#	println("$(a.id): wake up")
	a.state = 1

	[a]
end

function sleep(a::A1, model)
#	println("$(a.id): sleep")
	a.food -= 1

	[a]
end

function walk(a::A1, model)
#	println("$(a.id): walk")
	a.food -= 1

	[a]
end

function forage(a::A1, model)
#	println("$(a.id): forage")
	a.food += rand(1:5)

	[a]
end

function fallasleep(a::A1, model)
#	println("$(a.id): go to bed")
	a.state = 0

	[a]
end


const simulation = Simulation(PQScheduler{Float64}(), Model())


@processes SimpleTest simulation self::A1 begin
	# wake up
	@poisson(2.0)	~ self.state == 0					=> wakeup(self, simulation.model)
	@poisson(1.0)	~ self.state == 0					=> sleep(self, simulation.model)
	@poisson(0.5)	~ self.state == 1 && self.food > 3	=> walk(self, simulation.model)
	@poisson(1.0) 	~ self.state == 1 && self.food <= 3	=> forage(self, simulation.model)
	@poisson(3.0)	~ self.state == 1 && self.food > 1	=> fallasleep(self, simulation.model)
end

function setup(n)
	for i in 1:n
		spawn_SimpleTest(A1(i), simulation)
	end
end

function run(n)
	for i in 1:n
		next!(simulation.scheduler)
	end
	println(time_next(simulation.scheduler))
end


