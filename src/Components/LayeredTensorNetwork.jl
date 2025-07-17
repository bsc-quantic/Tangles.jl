using QuantumTags

struct LayeredTensorNetwork <: AbstractTensorNetwork
    tn::GeneralizedTensorNetwork
end

LayeredTensorNetwork() = LayeredTensorNetwork(GeneralizedTensorNetwork())
