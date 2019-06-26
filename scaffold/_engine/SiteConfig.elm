module SiteConfig exposing (SiteConfig, decoder, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias SiteConfig =
    { title : String }


encode : SiteConfig -> Encode.Value
encode config =
    Encode.object [ ( "title", Encode.string config.title ) ]


decoder : Decoder SiteConfig
decoder =
    Decode.map SiteConfig
        (Decode.field "title" Decode.string)
