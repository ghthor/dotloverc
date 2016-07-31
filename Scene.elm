module Scene exposing (..)

import List
import String
import Html exposing (Html, div, button, img)
import Html.Attributes as HA
import Html.App as App
import Html.Events exposing (onClick)
import Svg exposing (..)
import Svg.Attributes as SA
import Svg.Attributes exposing (..)

main =
    App.beginnerProgram
        { model = init
        , update = update
        , view = view
        }

-- Model

type alias Rect = {
    x : Int,
    y : Int,
    width : Int,
    height : Int
}
type EntityKind = Simple | Location | Item { name: String }

type alias Entity = {
    hitbox : Rect,
    description : String,
    kind : EntityKind
}

type Location
    = Apartment
    | RC

type alias LocationProperties =
    { imagePath : String
    , entities : List Entity
    , location : Location
    }

-- Entity should be constrained to kind == Item
takeItemFromLocation : Entity -> LocationProperties -> LocationProperties
takeItemFromLocation entity props =
    { props | entities = List.filter (\e -> e /= entity) props.entities }

type alias Model =
    { currentAction: Action
    , currentLocation: LocationProperties
    , otherLocations: List LocationProperties
    , infoText : String
    , inventory: List InventoryItem
    }

type alias InventoryItem = String

apartment =
    { imagePath = "img/apartment.jpg"
    , entities =
        [ { hitbox = { x = 0, y = 0, width = 300, height = 300 }, description = "apartment", kind = Location }
        , { hitbox = { x = 400, y = 0, width = 50, height = 50 }, description = "sky", kind = Item { name = "sky" } }
        ]
    , location = Apartment
    }


init = {
   currentAction = Look
   , currentLocation = apartment
   , otherLocations = []
   , infoText = "You wake up all alone, and all your friends are dead. Welcome to the game!"
   , inventory = [ "A banana", "5 dollars" ]
   }

type Action
   = Look
   | Move
   | Take

--init : Model
--init = On

-- Update
type Msg
    = ChangeAction Action
    | ExecuteAction Entity


update : Msg -> Model -> Model
update message model =
    case message of
        ChangeAction action ->
            { model | currentAction = action }

        ExecuteAction entity ->
            case model.currentAction of
                Look ->
                    { model | infoText = entity.description }

                Take ->
                    case entity.kind of
                        Item { name } ->
                            { model
                                | inventory = (name :: model.inventory)
                                , currentLocation = takeItemFromLocation entity model.currentLocation
                                , infoText = ("You have acquired " ++ name ++ "!")
                            }
                        _ ->
                            { model | infoText = "You can't take that." }
                _ ->
                    model

-- View

renderActionButton : Action -> Action -> Html Msg
renderActionButton currentAction a =
    let
        classes = HA.classList [ ("selected", a == currentAction) ]
    in
        button [ onClick (ChangeAction a), classes ] [ text (toString a) ]

renderInventoryItem : InventoryItem -> Html Msg
renderInventoryItem item =
    div [ class "inventoryitem" ] [ button [] [ text item ] ]


view : Model -> Html Msg
view ({inventory, currentAction, infoText} as model) =
    let
        cursor =
            case currentAction of
                Move -> "s-resize"
                Take -> "grab"
                Look -> "zoom-in"
        actionButtons = List.map (renderActionButton currentAction) [Look, Move, Take]
        inventoryItems =
            if List.isEmpty inventory then
               [ div [ class "inventoryempty" ] [ text "(empty)" ] ]
            else
               List.map renderInventoryItem inventory
        entityRects = List.map svgViewEntity model.currentLocation.entities
        sceneView =
            g [] ([ image [ xlinkHref "img/apartment.jpg", x "0", y "0", height "1080", width "1080" ] [] ] ++ entityRects)
        actionPane =
            div [ id "left" ]
                [ div [ class "menutitle" ] [ text "Actions" ]
                , div [ id "actionbuttons" ] actionButtons
                , div [ class "infotext" ] [ text infoText ]
                ]
        mainPane =
            div [ id "middle", HA.style [("cursor", cursor)] ]
                [ svg [ viewBox "0 0 1080 1080" ] [ sceneView ] ]
        inventoryPane =
            div [ id "right" ]
                [ div [ class "menutitle" ] [ text "Inventory" ]
                , div [ class "inventory" ] inventoryItems
                ]
    in
       div [ HA.id "container" ] [ actionPane, mainPane, inventoryPane ]
   {--
        div [  ] [ svg [viewBox "0 0 800 600", width "800px"] [(svgView model)]
               , div [] [ text ("Inventory: " ++ (if List.isEmpty inventory then "(empty)" else (String.join " ⚫ " inventory))) ]
               ]
               --}


svgViewEntity : Entity -> Svg Msg
svgViewEntity ({hitbox} as e) =
    let
        x_ = toString hitbox.x
        y_ = toString hitbox.y
        w = toString hitbox.width
        h = toString hitbox.height
    in
    rect [ x x_, y y_, height h, width w, SA.class "entity debug", onClick (ExecuteAction e) ] []
