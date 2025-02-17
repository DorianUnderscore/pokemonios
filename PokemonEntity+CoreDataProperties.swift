//
//  PokemonEntity+CoreDataProperties.swift
//  PokedexSwiftUI
//
//  Created by Dorian PAPIRIS on 2/17/25.
//
//

import Foundation
import CoreData


extension PokemonEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PokemonEntity> {
        return NSFetchRequest<PokemonEntity>(entityName: "PokemonEntity")
    }

    @NSManaged public var id: Int64
    @NSManaged public var imageUrl: String?
    @NSManaged public var name: String?
    @NSManaged public var stats: String?
    @NSManaged public var types: String?

}

extension PokemonEntity : Identifiable {

}
