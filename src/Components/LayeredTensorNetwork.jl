using QuantumTags
import QuantumTags: layers
using DelegatorTraits
using ArgCheck

struct LayeredTensorNetwork <: AbstractTensorNetwork
    tn::GenericTensorNetwork
    layers::Vector{Layer}
end

LayeredTensorNetwork() = LayeredTensorNetwork(GenericTensorNetwork(), Layer[])

ImplementorTrait(interface, tn::LayeredTensorNetwork) = ImplementorTrait(interface, tn.tn)
function DelegatorTrait(interface, tn::LayeredTensorNetwork)
    if ImplementorTrait(interface, tn.tn) === Implements()
        DelegateToField{:tn}()
    else
        DontDelegate()
    end
end

layers(tn::LayeredTensorNetwork) = unique(map(layer, all_sites_iter(tn)))

function pushlayer!(tn::LayeredTensorNetwork, layer_tn; layer::Layer=Layer(length(tn.layers) + 1))
    @argcheck ntensors(layer_tn) == nsites(layer_tn) "Each tensor in a layer must correspond to a site"
    @argcheck ninds(layer_tn) == nbonds(layer_tn) + nplugs(layer_tn) "Each index in a layer must correspond to a bond or plug"

    align!(tn => layer_tn)

    # create layer
    push!(tn.layers, layer)

    # add tensors and sites
    for _site in all_sites_iter(layer_tn)
        tn[LayerSite(_site, layer)] = layer_tn[_site]
    end

    # add in-layer bonds
    for _bond in all_bonds_iter(layer_tn)
        # set bond to pushed index
        tn[LayerBond(_bond, layer)] = layer_tn[_bond]

        # canonicalize bond index to avoid conflicts
        tn[LayerBond(_bond, layer)] = Index(LayerBond(_bond, layer))
    end

    # replace overlapping plugs with interlayer bonds
    for _plug in plugs_set_inputs(layer_tn)
        if hasplug(tn, _plug')
            # TODO match last layer containing the plug
            prev_layer = last(tn.layers)

            ilayer = InterLayer(prev_layer, layer)
            ibond = InterLayerBond(site(_plug), ilayer)

            unsetplug!(tn, _plug')
            tn[ibond] = layer_tn[_plug]

            # canonicalize interlayer bond index to avoid conflicts
            tn[ibond] = Index(ibond)
        else
            # set plug to pushed index
            tn[_plug] = layer_tn[_plug]

            # canonicalize plug index to avoid conflicts
            tn[_plug] = Index(LayerPlug(_plug, layer))
        end
    end

    # add new output plugs
    for _plug in plugs_set_outputs(layer_tn)
        if hasplug(tn, _plug')
            error("Output plug $_plug already exists in the LayeredTensorNetwork")
        end

        # set plug to pushed index
        tn[_plug] = layer_tn[_plug]

        # canonicalize plug index to avoid conflicts
        tn[_plug] = Index(LayerPlug(_plug, layer))
    end

    return tn
end
