push!(LOAD_PATH, "/cluster/home/ld2113/work/Final-Project/")
push!(LOAD_PATH, "/media/leander/Daten/Data/Imperial/Projects/Final Project/Final-Project")

using GPinf


# Define source data
numspecies = 5
srcset = :lin # :lin :osc :gnw
gnwpath = "/cluster/home/ld2113/work/data/thalia-simulated/InSilicoSize10-Yeast1_dream4_timeseries_one.tsv"

# Simulate source data
tspan = (0.0,20.0)
δt = 1.0
σ = 0.0 # Std.dev for ode + obs. noise or :sde

# Define possible parent sets
maxinter = 2
interclass = nothing # :add :mult nothing
usefix = true	#ODEonly

suminter = false	#ODEonly

gpnum = numspecies # For multioutput gp: how many outputs at once, for single: nothing

rmfl = false

@show numspecies; @show srcset; @show tspan; @show δt; @show σ; @show maxinter;
@show interclass; @show usefix; @show suminter; @show gpnum; @show rmfl;

################################################################################

odesys, sdesys, fixparm, trueparents, prmrng, prmrep = datasettings(srcset, interclass, usefix)

if srcset == :gnw
	x, y = readgenes(gnwpath)
else
	x, y = simulate(odesys, sdesys, numspecies, tspan, δt, σ)
end

xnew, xmu, xvar, xdotmu, xdotvar = interpolate(x, y, rmfl, gpnum)

parsets = construct_parsets(numspecies, maxinter, fixparm, interclass)

optimise_models!(parsets, fixparm, xmu, xdotmu, interclass, prmrng, prmrep)

weight_models!(parsets)

edgeweights = weight_edges(parsets, suminter, interclass)

ranks = get_true_ranks(trueparents, parsets, suminter)

bestmodels = get_best_id(parsets, suminter)

truedges, othersum = edgesummary(edgeweights,trueparents)

aupr_aic, aupr_bic, auroc_aic, auroc_bic = performance(edgeweights,trueparents)

println("AUPR AIC ", aupr_aic)
println("AUPR BIC ", aupr_bic)
println("AUROC AIC ", auroc_aic)
println("AUROC BIC ", auroc_bic)

# output, thalia_aupr, thalia_auroc = networkinference(y, trueparents)
# println("AUPR ", thalia_aupr)
# println("AUROC ", thalia_auroc)
