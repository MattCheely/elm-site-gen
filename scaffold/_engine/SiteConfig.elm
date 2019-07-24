module SiteConfig exposing (SiteConfig, decoder, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias SiteConfig =
    { title : String

    -- TODO: Make tags a union type
    , tags : List String
    }


encode : SiteConfig -> Encode.Value
encode config =
    Encode.object
        [ ( "title", Encode.string config.title )
        , ( "tags", Encode.list Encode.string config.tags )
        ]


decoder : Decoder SiteConfig
decoder =
    Decode.map2 SiteConfig
        (Decode.field "title" Decode.string)
        (Decode.field "tags" (Decode.list Decode.string))
