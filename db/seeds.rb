# db/seeds.rb
# -----------------------------------------------------------------------------
# Seedet 20 Users, 15–25 aktuelle Posts (paraphrasierte Schlagzeilen-Themen),
# dazu mehrere Kommentare je Post sowie Replies auf Kommentare.
# Sicher für mehrfaches Ausführen (find_or_create_by / simple Dedupe).
# -----------------------------------------------------------------------------

require "securerandom"

puts "==> Seeding…"

# ----------------------------------------------------------------------------- 
# 0) Optionale Bereinigung (nur aktivieren, wenn du wirklich alles neu willst)
# -----------------------------------------------------------------------------
NUKE = ENV["NUKE"] == "1"
if NUKE
  puts "!! NUKE=1 erkannt – lösche Comments, Posts, Users (außer ggf. Admin)…"
  Comment.delete_all
  Post.delete_all
  # Falls du einen Admin behalten willst, passe die where-Klausel an
  User.delete_all
  # Primärschlüssel ggf. zurücksetzen (für Postgres ok; bei SQLite egal)
  begin
    %w[users posts comments].each do |t|
      ActiveRecord::Base.connection.reset_pk_sequence!(t)
    end
  rescue => e
    puts "(Hinweis) PK-Sequence nicht zurückgesetzt: #{e.message}"
  end
end

# ----------------------------------------------------------------------------- 
# 1) 20 Benutzer
# -----------------------------------------------------------------------------
first_names = %w[
  Alex Finn Luca Mara Jana Tom Lara Ben Zoe Paul Emma Noah Mia Leon Nina Jonas
  Sara Tim Joel Eva Max
]
last_names  = %w[
  Weber Keller Baumann Steiner Roth Vogel Hartmann Meier Keller Schneider Fischer
  Wagner Hoffmann Schmid Schmitt Walter König Fuchs Albrecht Sommer
]

users = []
20.times do |i|
  fn = first_names[i % first_names.size]
  ln = last_names[i % last_names.size]
  name  = "#{fn} #{ln}"
  email = "#{fn.downcase}.#{ln.downcase}.#{i+1}@example.com"

  user = User.where(email: email).first_or_initialize
  user.name = name if user.respond_to?(:name)
  user.password = "password123"
  user.password_confirmation = "password123"
  # Falls :confirmable aktiv wäre:
  user.confirmed_at = Time.current if user.respond_to?(:confirmed_at) && user.confirmed_at.blank?
  user.save!
  users << user
end
puts "→ Users: #{User.count}"

# ----------------------------------------------------------------------------- 
# 2) Schlagzeilen-Themen (paraphrasiert; Stand Okt 2025)
#    Quelle: Reuters, AP, The Guardian, Bloomberg (siehe unten)
# -----------------------------------------------------------------------------
HEADLINES = [
  "US-Regierung im Shutdown – Einigung im Senat scheitert erneut",
  "Debatte um Einsatz des Insurrection Act spitzt sich zu",
  "Greta Thunberg erhebt Foltervorwürfe nach Gaza-Flottillen-Festnahme",
  "Erntemond-Supermoon begeistert Himmelgucker weltweit",
  "Dow & S&P schließen auf Rekord – Tech schwankt",
  "Channel 4 sichert sich Boat-Race-Rechte von Oxford vs. Cambridge",
  "BBC diskutiert Mitfinanzierung des World Service aus Verteidigungsetat",
  "Proteste und Gegendemonstrationen vor ICE-Standorten eskalieren",
  "US-Unis sollen Trumps Agenda zustimmen, um Bundesmittel zu erhalten – Debatte entfacht",
  "Dell hebt Prognose dank KI-Boom deutlich an",
  "Indirekte Gespräche Israel–Hamas gehen in Kairo weiter",
  "Frankreich ringt um Ausweg aus politischer Krise",
  "Chicago & Illinois klagen gegen Bundespläne zur Nationalgarde",
  "Bilder des Tages: Extremwetter, Politik und Kultur im Schnellüberblick",
  "Nobelpreis-Physik: Auszeichnung für Quantentechnologie",
  "Supermoon über New York – spektakuläre Fotos viral",
  "US-Börsen: Volatilität trotz Rekorden – Anleger bleiben vorsichtig",
  "Kultur: ‘Devil Wears Prada 2’ löst Hype am Set in Mailand aus",
  "Sportrechte-Rochade: Öffentlich-Rechtliche setzen stärker auf Frauenfußball",
  "Debatte über Medienfinanzierung im Zeitalter der Desinformation"
].uniq

# 15–25 Posts
post_count = rand(20..25)
posts = []
HEADLINES.sample(post_count).each_with_index do |title, idx|
  author = users.sample
  body = [
    "Kurze Einordnung: #{title}.",
    "Was denkt ihr dazu? Trends ändern sich stündlich – Quellenlage bleibt dynamisch.",
    "Meine 2 Cent: Differenzierte Sicht schadet nie. Quellen prüfen!"
  ].join("\n\n")

  post = Post.where(title: title).first_or_initialize
  post.user  = author if post.respond_to?(:user) && post.user.blank?
  post.body  = body
  # etwas Streuung in den Zeiten
  post.created_at ||= rand(1..7).days.ago
  post.updated_at = [post.created_at + rand(1..3).hours, Time.current].min
  post.save!
  posts << post
end
puts "→ Posts: #{Post.count} (neu: #{posts.size})"

# ----------------------------------------------------------------------------- 
# 3) Kommentare & verschachtelte Replies
# -----------------------------------------------------------------------------
TOP_LEVEL_PER_POST = (3..6)
REPLIES_PER_COMMENT = (0..3)

sample_comments = [
  "Spannend. Quelle?",
  "Sehe ich ähnlich – aber Vorsicht mit voreiligen Schlüssen.",
  "Hat jemand einen guten Longread dazu?",
  "Die Marktreaktion überrascht mich nicht.",
  "Politisch heikel, kommunikativ noch heikler.",
  "Gutes Thema! Bitte Thread mit Updates pflegen.",
  "Faktencheck: Gibt’s Widerspruch aus anderen Medien?",
  "Wow, das Foto ist irre.",
  "Mal abwarten, wie der Senat reagiert.",
  "Das wird noch Wellen schlagen."
]

posts.each do |post|
  # nur top-level-Kommentare (parent_id: nil)
  rand(TOP_LEVEL_PER_POST).times do
    commenter = users.sample
    c = Comment.create!(
      post: post,
      user: commenter,
      body: sample_comments.sample,
      parent_id: nil
    )

    # Replies (verschachtelt unterhalb des Top-Level-Kommentars)
    rand(REPLIES_PER_COMMENT).times do
      replier = (users - [commenter]).sample
      Comment.create!(
        post: post,
        user: replier,
        body: "Reply: #{sample_comments.sample}",
        parent: c
      )
    end
  end
end

puts "→ Comments total: #{Comment.count}"
puts "==> Done."
