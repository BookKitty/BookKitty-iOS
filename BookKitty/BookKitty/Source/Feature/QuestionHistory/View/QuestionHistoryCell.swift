//
//  QuestionHistoryCell.swift
//  BookKitty
//
//  Created by Neoself on 2/5/25.
//
import DesignSystem
import UIKit

final class QuestionHistoryCell: UITableViewCell {
    // MARK: - Static Properties

    // MARK: - Internal

    static let identifier = "QuestionHistoryCell"

    // MARK: - Properties

    // MARK: - Private

    private let containerView = UIView().then {
        $0.backgroundColor = Colors.background1
        $0.layer.cornerRadius = Vars.radiusMini
        $0.clipsToBounds = true
    }

    private let dateLabel = CaptionLabel(weight: .regular).then {
        $0.textColor = Colors.fontSub1
    }

    private let questionLabel = BodyLabel(weight: .regular).then {
        $0.numberOfLines = 2
    }

    private let recommendedBooksStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 12
        $0.distribution = .fill
        $0.alignment = .leading
    }

    // MARK: - Lifecycle

    override public func layoutSubviews() {
        super.layoutSubviews()

        containerView.setBasicShadow(radius: Vars.radiusTiny)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupLayouts()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Functions

    func configure(with questionAnswer: QuestionAnswer) {
        let isOverlapNeeded = questionAnswer.recommendedBooks.count > 3

        dateLabel.text = DateFormatter.shared.string(from: questionAnswer.createdAt)
        questionLabel.text = questionAnswer.userQuestion
        questionLabel.lineBreakMode = .byTruncatingTail

        recommendedBooksStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if isOverlapNeeded {
            recommendedBooksStackView.spacing = -48
        }

        for book in questionAnswer.recommendedBooks {
            let imageView = HeightFixedImageView(
                imageLink: book.thumbnailUrl?.absoluteString ?? "",
                height: .small
            )

            imageView.setRadius(to: true)

            if isOverlapNeeded {
                imageView.transform = CGAffineTransform(rotationAngle: 5 * .pi / 180)
            }

            recommendedBooksStackView.addArrangedSubview(imageView)
        }
    }

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(containerView)

        [dateLabel, questionLabel, recommendedBooksStackView]
            .forEach { containerView.addSubview($0) }
    }

    private func setupLayouts() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(8.0)
        }

        dateLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
            $0.height.equalTo(18.0)
        }

        questionLabel.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(Vars.spacing12)
            $0.leading.trailing.equalToSuperview().inset(Vars.paddingReg)
        }

        recommendedBooksStackView.snp.makeConstraints { make in
            make.top.equalTo(questionLabel.snp.bottom).offset(Vars.spacing24)
            make.bottom.equalToSuperview().inset(Vars.paddingReg)

            make.leading.equalToSuperview().inset(Vars.paddingReg)
        }
    }
}

extension DateFormatter {
    fileprivate static let shared: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter
    }()
}
