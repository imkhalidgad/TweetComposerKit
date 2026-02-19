import Foundation

enum TweetMapper {

    /// Maps Twitter API response DTO to domain entity.
    static func toEntity(_ dto: PostTweetResponseDTO.TweetDataDTO) -> Tweet {
        Tweet(id: dto.id, text: dto.text)
    }
}
