using QuantumTags
import QuantumTags: layers
using DelegatorTraits

struct LayeredTensorNetwork <: AbstractTensorNetwork
    tn::GenericTensorNetwork
end

LayeredTensorNetwork() = LayeredTensorNetwork(GenericTensorNetwork())

ImplementorTrait(interface, tn::MPS) = ImplementorTrait(interface, tn.tn)
function DelegatorTrait(interface, tn::MPS)
    if ImplementorTrait(interface, tn.tn) === Implements()
        DelegateToField{:tn}()
    else
        DontDelegate()
    end
end

layers(tn::LayeredTensorNetwork) = unique(map(layer, all_sites_iter(tn)))
