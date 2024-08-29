import Category "../entities/Category";
import CategoryRepository "../repositories/CategoryRepository";
import ReputationRepository "../repositories/ReputationRepository";

module {
    public class DeleteCategoryUseCase(categoryRepo : CategoryRepository.CategoryRepository, reputationRepo : ReputationRepository.ReputationRepository) {
        public func execute(categoryId : Category.CategoryId) : async Bool {
            let repDeleted = await reputationRepo.deleteCategoryReputations(categoryId);
            let categoryDeleted = await categoryRepo.deleteCategory(categoryId);
            repDeleted and categoryDeleted;
        };
    };
};
