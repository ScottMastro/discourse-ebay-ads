def create_system_post(topic_id, post_content)
    user = Discourse.system_user
    PostCreator.new(user,
      topic_id: topic_id,
      raw: post_content
    ).create!
end

