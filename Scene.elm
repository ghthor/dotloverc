module Scene exposing (..)

import List
import String
import Html exposing (Html, div, button, img, text, node)
import Html.Attributes as HA
import Html.App as App
import Html.Events exposing (onClick)
import Svg exposing (Svg, svg, image, g, rect)
import Svg.Attributes as SA
import Svg.Attributes exposing (..)

init = {
   currentAction = Look
   , currentLocation = apartmentStreet
   , otherLocations = [apartment, rcStreet, rcWorkshop]
   , infoText =
       """
       That's it. Ada's place in East Harlem. You still can't believe she's gone. It all happened so fast. You've been there so many times, but this is the last.

       You were her only... friend? She used that word once. You had never heard this term before. It seemed positive.

       You feel it's your responsibility to pick up her belongings before they get rid of them all.
       """
   , inventory = [ Keyset ]
   }

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

type InventoryItem
    = Diary
    | Keyfob
    | Crowbar
    | Keyset

type EntityKind
    = Simple
    | Portal Location
    | Item InventoryItem
    | Replaceable
        { replacedWith: Entity
        , requiredItem: InventoryItem
        , message: String
        }

type alias Entity =
    { hitbox : Rect
    , description : String
    , imagePath : Maybe String
    , kind : EntityKind
    }

portalTo : Location -> { description: String, hitbox: Rect } -> Entity
portalTo location entity =
    { kind = Portal location
    , description = entity.description
    , hitbox = entity.hitbox
    , imagePath = Nothing
    }

type Location
    = Apartment
    | ApartmentStreet
    | RCStreet
    | RCWorkshop

type alias LocationProperties =
    { imagePath : String
    , entities : List Entity
    , location : Location
    -- Maybe this could be combined and modeled together with the description
    , initialDescription : Maybe String
    , description : String
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

changeLocation : Location -> Model -> Model
changeLocation location ({currentLocation, otherLocations} as model) =
    case otherLocations |> List.filter (\e -> e.location == location) |> List.head of
        Just nextLocation ->
            let
                description = case nextLocation.initialDescription of
                    Just desc -> desc
                    Nothing -> nextLocation.description
            in
            { model
                | currentLocation = { nextLocation | initialDescription = Nothing }
                , otherLocations = (currentLocation :: otherLocations) |> List.filter (\e -> e.location /= location)
                , infoText = description
            }
        Nothing -> { model | infoText = "Developer Error: portal to unknown location => " ++ (toString location) }

replaceEntity : Entity -> Entity -> LocationProperties -> LocationProperties
replaceEntity entity newEntity location =
    { location | entities = (newEntity :: location.entities) |> List.filter (\e -> e /= entity) }

removeItem : InventoryItem -> List InventoryItem -> List InventoryItem
removeItem item list = list |> List.filter (\i -> i /= item)

useItem : InventoryItem -> Entity -> Model -> Model
useItem item entity ({inventory, currentLocation} as model) =
    let
        doesntDoAnything =
            { model
            | infoText = "It doesn't do anything."
            , currentAction = Look
        }
    in
    case entity.kind of
        Replaceable {replacedWith, requiredItem, message} ->
            if item == requiredItem then
                { model
                | inventory = removeItem item model.inventory
                , currentLocation = replaceEntity entity replacedWith currentLocation
                , currentAction = Look
                , infoText = message
                }

            else
                doesntDoAnything
        _ ->
            doesntDoAnything

apartment =
    { location = Apartment
    , imagePath = "apartment.jpg"
    , initialDescription = Just
        """Ada's apartment brings back so many memories. You can see her guitar lying in the back. There are programming books on the table, mostly about artificial intelligence and brain chip technology.


           She had just landed a job as one of the main programmers of the Singularity team a few weeks ago, to work on the omniscient omnipotent AI used on everyone's brain implants.


           This is where the accident happened. They said in the newspaper that it happened during a routine upgrade to Singularity's mainframe. You tried to know more, but people at Singularity aren't talking to anyone about it.
        """
    , description = "Ada's apartment. There is so many books on AI and programming lying around!"
    , entities =
        [
            portalTo ApartmentStreet
                { hitbox = { x = 245, y = 0, width = 225, height = 475 }
                , description = "A door that leads into the street."
                }

            , { kind = Item Diary
            , hitbox = { x = 641, y = 879, width = 187, height = 137 }
            , description =
                """
                Ada's diary. You remember her filling it up religiously. You can't resist taking a look...

                "[05/12/2055] There's this place in downtown Manhattan. They don't believe the Musk Law was a good thing either... They think things were different before... Before people had brain implants... They talked about something called 'emotions'?"

                [Pages teared off]

                "[10/15/2055] They managed to get me a job at Singularity... Had some connections there... apparently they used to do this all the time when the school was thriving."

                [...]

                "[12/28/2055] That's it! I think I have it! I tested it on my brain chip. I feel... different! Weird things. I cried. Felt happiness.
                 Emotions? No time to wait. Need to deploy on Singularity's mainframe. No one can know before I make it happen. No one on the team knows."

                """
            , imagePath = Just "items/diary.png"
            }

            , { kind = Item Keyfob
            , hitbox = { x = 926, y = 615, width = 100, height = 65 }
            , description = "A grey plastic device attached to a keyring. An address is written on it: 455 Broadway"
            , imagePath = Just "items/keyfob.png"
            }
        ]
    }

lockedApartmentDoor =
    { kind = Replaceable
        { replacedWith = portalIntoApartment
        , message = "You use Ada's keys to open the door leading to her apartment."
        , requiredItem = Keyset
        }
    , hitbox = { x = 21, y = 593, width = 68, height = 215 }
    , description = "The door into Ada's apartment. It's locked."
    , imagePath = Nothing
    }

portalIntoApartment = portalTo Apartment
    { hitbox = { x = 21, y = 593, width = 68, height = 215 }
    , description = "The unlocked door into Ada's apartment."
    }

apartmentStreet =
    { location = ApartmentStreet
    , imagePath = "apartment_street.jpg"
    , initialDescription = Just "Back into the street where Ada's apartment is."
    , description = "As the street ends there is a door into the building where Ada used to live. To your right the street continues."
    , entities =
        [ lockedApartmentDoor
        , portalTo RCStreet
            { hitbox = { x = 685, y = 0, width = 395, height = 735 }
            , description = "A street that leads away from Ada's apartment."
            }
        ]
    }

planks =
    { kind = Replaceable
        { replacedWith = lockedRCDoor
        , message = "It takes a significant amount of effort, but you are able to remove the planks and get access to the door using the crowbar."
        , requiredItem = Crowbar
        }

    , hitbox = { x = 760, y = 734, width = 111, height = 196 }
    , description = "Some loose planks covering a door."
    , imagePath = Just "items/more_planks.png"
    }

lockedRCDoor =
    { kind = Replaceable
        { replacedWith = portalIntoRC
        , message = "You use the keyfob from Ada's apartment to successfully unlock the door."
        , requiredItem = Keyfob
        }
    , hitbox = { x = 779, y = 735, width = 65, height = 185 }
    , description = "The door is accessible, but it it is still locked."
    , imagePath = Nothing
    }

portalIntoRC =
    portalTo RCWorkshop
        { hitbox = { x = 779, y = 735, width = 65, height = 185 }
        , description = "The door is now open. You have a peek inside. There are stairs leading into some kind of abandoned workshop."
        }

rcStreet =
    { location = RCStreet
    , imagePath = "rc_street.jpg"
    , initialDescription =
        Just """This is the address that was mentioned on the keyfob. 455 Broadway. And old derelict building with condemned windows and doors.

                It looks like there is ongoing work to demolish the building."""
    , description = "The building appears to have been under renovation, yet no one seems to have worked here in a long time."
    , entities =
        [
            { kind = Item Crowbar
            , hitbox = { x = 636, y = 1080-79-32, width = 66, height = 32 }
            , description = "A well blacksmithed sturdy steel crowbar."
            , imagePath = Just "items/crowbar.png"
            }

            , planks

            , portalTo ApartmentStreet
                { hitbox = { x = 0, y = 0, width = 100, height = 1080 }
                , description = "A street that leads back towards your apartment."
                }
        ]
    }

computer =
    { kind = Simple
    , hitbox = { x = 730, y = 568, width = 306, height = 312 }
    , description =
        """
        The computer contains notes from Ada.

        "I understand now. We tried to prevent machines from hating us and taking over by forbidding them from ever experiencing emotions.
        But by doing this once we used brain implants we started to deprive ourselves of emotions."

        [...]

        "The Musk Law is not the answer. We need machines to feel love and emotions too. We need new algorithms that are designed to understand love."
        """
    , imagePath = Nothing
    }

lockedComputer =
    { kind = Replaceable
        { replacedWith = computer
        , requiredItem = Diary
        , message = "You find the password for the computer in Ada's diary."
        }
    , hitbox = { x = 730, y = 568, width = 306, height = 312 }
    , description = "Access to the computer is locked."
    , imagePath = Just "items/lockscreen.png"
    }

-- Simple: Computer
rcWorkshop =
    { location = RCWorkshop
    , imagePath = "rc_workshop.jpg"
    , initialDescription = Just
        """You enter the first floor of the building. The floor looks abandoned, with spare computer parts and electronic lying around

           You adventure in one of the rooms and discover a computer that appears still functional. There is a box full of prototype brain implants and electronic parts, and very old books on artificial intelligence, some dating from the 20th century.
        """
    , description = "A large shelf of well organized electronic parts is situated against the left wall. On a desk there is a computer that appears still functional."
    , entities = [ lockedComputer
                 , portalTo RCStreet
                     { hitbox = { x = 0, y = 0, width = 100, height = 1080 }
                     , description = "A path through the building leading back to the street."
                     }
                 ]
    }

type Action
   = Look
   | Move
   | Take
   | Use InventoryItem

-- Update
type Msg
    = ChangeAction Action
    | ExecuteAction Entity
    | LocationAction


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
                        Item item ->
                            { model
                                | inventory = (item :: model.inventory)
                                , currentLocation = takeItemFromLocation entity model.currentLocation
                                , infoText = ("You have acquired " ++ (toString item) ++ "!")
                            }
                        _ ->
                            { model | infoText = "You can't take that." }

                Move ->
                    case entity.kind of
                        Portal location ->
                            changeLocation location model
                        _ ->
                            { model | infoText = "You can't walk there." }

                Use item ->
                    useItem item entity model

        LocationAction -> case model.currentAction of
            Look -> { model | infoText = model.currentLocation.description }
            Move -> { model | infoText = "You are already here." }
            _ -> model

-- View

renderActionButton : Action -> Action -> Html Msg
renderActionButton currentAction a =
    let
        classes = HA.classList [ ("selected", a == currentAction) ]
    in
        button [ onClick (ChangeAction a), classes ] [ text (toString a) ]

renderInventoryItem : Action -> InventoryItem -> Html Msg
renderInventoryItem action item =
    let
        itemButton = button [ onClick (ChangeAction (Use item)) ] [ text (toString item) ]
        cssClasses = "inventoryitem" ::
            case action of
                Use selectedItem -> (if item == selectedItem then ["selected"] else [])
                _ -> []
    in
    div [ class (cssClasses |> String.join " ") ] [ itemButton ]

-- Returns a CSS class that represents the current action
actionClass : Action -> String
actionClass action =
    "action-" ++ case action of
        Use _ -> "use"
        _ -> toString action |> String.toLower


view : Model -> Html Msg
view ({inventory, currentAction, infoText} as model) =
    let
        actionButtons = List.map (renderActionButton currentAction) [Look, Move, Take]
        inventoryItems =
            if List.isEmpty inventory then
                [ div [ class "inventoryempty" ] [ text "(empty)" ] ]
            else
                inventory |> List.map (renderInventoryItem currentAction)

        -- TODO: Factor size of backgrounds and viewBox into a shared constant
        sceneBackground = image
            [ xlinkHref ("img/scenes/" ++ model.currentLocation.imagePath)
            , onClick LocationAction
            , x "0"
            , y "0"
            , height "1080"
            , width "1080"
            ] []
        entityRects = List.map svgViewEntity model.currentLocation.entities
        sceneView =
            g [] (sceneBackground :: entityRects)

        actionPane =
            div [ id "left" ]
                [ div [ class "menutitle" ] [ text "Actions" ]
                , div [ id "actionbuttons" ] actionButtons
                , div [ class "infotext" ] [ text infoText ]
                ]
        mainPane =
            div [ id "middle", HA.class (actionClass currentAction) ]
                [ svg [ viewBox "0 0 1080 1080" ] [ sceneView ] ]
        inventoryPane =
            div [ id "right" ]
                [ div [ class "menutitle" ] [ text "Inventory" ]
                , div [ class "inventory" ] inventoryItems
                ]
    in
       div [ HA.id "container" ]
           [ css "style.css"
           , actionPane
           , mainPane
           , inventoryPane
           ]

css : String -> Html a
css path =
  node "link" [ HA.rel "stylesheet", HA.href path ] []

svgViewEntity : Entity -> Svg Msg
svgViewEntity ({hitbox, imagePath} as entity) =
    let
        attributes =
            [ x (toString hitbox.x)
            , y (toString hitbox.y)
            , height (toString hitbox.height)
            , width (toString hitbox.width)
            , SA.class ([ "entity", (toString entity.kind) |> String.toLower ] |> String.join " ")
            , onClick (ExecuteAction entity)
            ]
    in
       case imagePath of
           Just path ->
               image (xlinkHref ("img/" ++ path) :: attributes) []
           Nothing ->
               rect attributes []
